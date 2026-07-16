import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/login/domain/entities/login_response.dart';
import '../../features/login/domain/entities/user_profile.dart';
import '../services/notification_service.dart';

/// Dueño único del estado de sesión de la app.
///
/// Reemplaza al antiguo almacén de sesión de facto que vivía en
/// `LoginProvider`. Es la única fuente de verdad de token, rol e ids del
/// usuario autenticado. Se registra en [CoreModule] y se expone a la app vía
/// un `ChangeNotifierProvider.value` en `app.dart`.
///
/// Persistencia:
/// - token -> `flutter_secure_storage` (cifrado en reposo).
/// - ids/rol/subscription -> `shared_preferences` (texto plano, no sensible).
/// - `userProfile` -> SOLO en memoria (es PII: email/teléfono/cédula); se
///   re-obtiene en [restore] mediante el `profileLoader`.
class SessionManager extends ChangeNotifier {
  // ---- Claves de almacenamiento ----
  static const String _kToken = 'session.token'; // solo en secure storage
  static const String _kUserId = 'session.user_id';
  static const String _kRole = 'session.role';
  static const String _kPatientId = 'session.patient_id';
  static const String _kDoctorId = 'session.doctor_id';
  static const String _kMedicalRecordId = 'session.medical_record_id';
  static const String _kReceptionistId = 'session.receptionist_id';
  static const String _kSubscriptionStatus = 'session.subscription_status';

  final FlutterSecureStorage _secureStorage;

  SessionManager({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  // ---- Estado en memoria (fuente única de verdad) ----
  String? _token;
  String? _role;
  int? _userId;
  int? _patientId;
  int? _doctorId;
  int? _medicalRecordId;
  int? _receptionistId;
  String? _subscriptionStatus;
  UserProfile? _userProfile;

  /// Callback inyectado en dos fases (ver [attachProfileLoader]) para obtener
  /// el perfil sin que [SessionManager] dependa de un usecase en su
  /// constructor (rompe el ciclo ApiClient <-> SessionManager).
  Future<UserProfile?> Function(int userId, {int? doctorId})? _profileLoader;

  // ---- Getters (espejo del antiguo LoginProvider para migración 1:1) ----
  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  int? get patientId => _patientId;
  int? get doctorId => _doctorId;
  int? get medicalRecordId => _medicalRecordId;
  int? get receptionistId => _receptionistId;
  String? get subscriptionStatus => _subscriptionStatus;
  UserProfile? get userProfile => _userProfile;

  bool get isDoctor => _role == 'doctor' || _role == 'doctor(a)';

  /// True cuando un doctor autenticado no tiene una suscripción activa y debe
  /// pasar por la pantalla de pago antes de usar el sistema.
  bool get needsSubscriptionGate => isDoctor && _subscriptionStatus != 'active';

  String get name => _userProfile?.name ?? '';
  String get lastName => _userProfile?.lastName ?? '';
  String get email => _userProfile?.email ?? '';
  String get fullName => '$name $lastName'.trim();

  // ---- Nuevos derivados (opt-in; permisivos, sin adoptar aún en páginas) ----
  bool get isAuthenticated => _token != null;
  bool get isReceptionist =>
      _role == 'receptionist' ||
      _role == 'recepcionista' ||
      _role == 'recepcionist';
  bool get isPatient => _role == 'paciente' || _role == 'patient';

  // ---- Ciclo de vida ----

  /// Fase 2 del wiring en el composition root: adjunta el cargador de perfil.
  /// `loader = (id, {doctorId}) => loginModule.getProfileUseCase.execute(id, doctorId: doctorId)`.
  /// El `doctorId` es clave para doctores: sin él, `getUserProfile` escanea
  /// `/doctors/1..50` uno por uno para descubrir el `doctor_id`; pasándolo
  /// (viene en la respuesta del login) esa ráfaga se salta por completo.
  void attachProfileLoader(
    Future<UserProfile?> Function(int userId, {int? doctorId}) loader,
  ) {
    _profileLoader = loader;
  }

  /// Encapsula la ramificación por rol y la preservación del `patientId` que
  /// pudo dejar el registro (`setPatientId`). Debe completar `_persist` + set
  /// de campos ANTES de resolver: `login_page`/`register_page` leen
  /// `role`/`needsSubscriptionGate` inmediatamente después.
  Future<void> saveFromLogin(LoginResponse response) async {
    _token = response.accessToken;
    _role = response.role;
    _userId = response.userId;
    _subscriptionStatus = response.subscriptionStatus;

    if (isDoctor) {
      _doctorId = response.doctorId;
      _medicalRecordId = null;
      _receptionistId = null;
      // _patientId se deja como está (null en la práctica para doctores).
    } else {
      // Preserva el patientId puesto por register.setPatientId cuando el
      // backend no devuelve uno.
      _patientId = response.patientId ?? _patientId;
      _doctorId = response.doctorId;
      _medicalRecordId = response.medicalRecordId;
      _receptionistId = response.receptionistId;
    }

    // Best-effort: si falla queda null; la UI ya maneja userProfile null.
    // Se pasa `_doctorId` (que ya viene del login) para evitar el escaneo
    // secuencial de `/doctors/1..50` al construir el perfil del doctor.
    try {
      _userProfile = await _profileLoader?.call(_userId!, doctorId: _doctorId);
    } catch (e) {
      debugPrint('SessionManager: no se pudo obtener el perfil tras login: $e');
      _userProfile = null;
    }

    await _persist();

    // Registrar el dispositivo para notificaciones push tras iniciar sesión
    NotificationService.registerDevice();

    notifyListeners();
  }

  /// Puente register -> login. `register_page` lo llama ANTES del login;
  /// [saveFromLogin] lo respeta vía `response.patientId ?? _patientId`.
  void setPatientId(int id) {
    _patientId = id;
    // El I/O de persistencia es fire-and-forget (no bloquea la UI).
    _writePrefInt(_kPatientId, id);
    notifyListeners();
  }

  /// Lo llama [ProfileProvider] tras un update de perfil exitoso. Solo memoria:
  /// el perfil es PII y nunca se persiste a disco.
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  /// Reemplaza el token vigente por uno recién emitido (p. ej. tras activarse
  /// la suscripción de un doctor). El gating lee `subscription_status` desde el
  /// JWT, así que hay que sustituir el token; opcionalmente se actualiza el
  /// `subscriptionStatus` en memoria/prefs para que [needsSubscriptionGate]
  /// deje de disparar de inmediato.
  Future<void> applyRefreshedToken(
    String token, {
    String? subscriptionStatus,
  }) async {
    if (token.isEmpty) return;
    _token = token;
    if (subscriptionStatus != null) _subscriptionStatus = subscriptionStatus;
    notifyListeners();

    await _secureStorage.write(key: _kToken, value: _token);
    if (subscriptionStatus != null) {
      final prefs = await SharedPreferences.getInstance();
      await _setOrRemoveString(
        prefs,
        _kSubscriptionStatus,
        _subscriptionStatus,
      );
    }
  }

  /// Restaura la sesión al arranque. Devuelve true si hay sesión válida.
  ///
  /// Dos guardas: (1) inactividad > [inactivityTimeout] -> descarta; (2) sonda
  /// de liveness contra el backend vía `profileLoader` -> si falla (token
  /// vencido / red), descarta. Cubre el token vencido en arranque frío sin
  /// necesitar infraestructura de 401 en sesión.
  Future<bool> restore() async {
    final token = await _secureStorage.read(key: _kToken);
    if (token == null) return false;

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(_kUserId);
    _role = prefs.getString(_kRole);
    _patientId = prefs.getInt(_kPatientId);
    _doctorId = prefs.getInt(_kDoctorId);
    _medicalRecordId = prefs.getInt(_kMedicalRecordId);
    _receptionistId = prefs.getInt(_kReceptionistId);
    _subscriptionStatus = prefs.getString(_kSubscriptionStatus);

    _token = token; // ApiClient lo verá vía el tokenProvider callback.

    // Sonda de liveness: un getProfile de una vez valida el token.
    // `_doctorId` restaurado de prefs evita reescanear `/doctors/1..50`.
    if (_userId != null && _profileLoader != null) {
      try {
        _userProfile = await _profileLoader!.call(
          _userId!,
          doctorId: _doctorId,
        );
      } catch (e) {
        debugPrint('SessionManager: sonda de liveness falló en restore: $e');
        await clear();
        return false;
      }
    }

    notifyListeners();

    // Registrar/actualizar dispositivo en segundo plano al restaurar sesión
    NotificationService.registerDevice();

    return true;
  }

  /// Logout / teardown. Orden crítico: memoria + notify SÍNCRONO primero
  /// (para que `isAuthenticated` pase a false y el token pull de ApiClient
  /// devuelva null de inmediato), luego el borrado asíncrono en storage.
  Future<void> clear() async {
    // El token FCM NO se desregistra aquí a propósito: es un token de
    // dispositivo (no de sesión), para que los recordatorios diarios sigan
    // llegando aunque el usuario haya cerrado sesión.
    _token = null;
    _role = null;
    _userId = null;
    _patientId = null;
    _doctorId = null;
    _medicalRecordId = null;
    _receptionistId = null;
    _subscriptionStatus = null;
    _userProfile = null;
    notifyListeners();

    await _secureStorage.delete(key: _kToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kRole);
    await prefs.remove(_kPatientId);
    await prefs.remove(_kDoctorId);
    await prefs.remove(_kMedicalRecordId);
    await prefs.remove(_kReceptionistId);
    await prefs.remove(_kSubscriptionStatus);
  }

  // ---- Persistencia interna ----

  Future<void> _persist() async {
    await _secureStorage.write(key: _kToken, value: _token);
    final prefs = await SharedPreferences.getInstance();
    await _setOrRemoveInt(prefs, _kUserId, _userId);
    await _setOrRemoveString(prefs, _kRole, _role);
    await _setOrRemoveInt(prefs, _kPatientId, _patientId);
    await _setOrRemoveInt(prefs, _kDoctorId, _doctorId);
    await _setOrRemoveInt(prefs, _kMedicalRecordId, _medicalRecordId);
    await _setOrRemoveInt(prefs, _kReceptionistId, _receptionistId);
    await _setOrRemoveString(prefs, _kSubscriptionStatus, _subscriptionStatus);
  }

  Future<void> _writePrefInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<void> _setOrRemoveInt(
    SharedPreferences prefs,
    String key,
    int? value,
  ) => value == null ? prefs.remove(key) : prefs.setInt(key, value);

  Future<void> _setOrRemoveString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) => value == null ? prefs.remove(key) : prefs.setString(key, value);
}
