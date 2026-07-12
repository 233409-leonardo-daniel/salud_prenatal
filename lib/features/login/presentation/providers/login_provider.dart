import 'package:flutter/foundation.dart';
import '../../data/models/login_request.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/login_usecase.dart';
import '../pages/login_state.dart';
import '../../../../core/session/session_manager.dart';

/// Provider del FLUJO de login únicamente.
///
/// El estado de sesión (token, rol, ids, perfil) ya NO vive aquí: es propiedad
/// de [SessionManager]. Mientras las páginas de features no se migren a leer
/// [SessionManager] directamente, este provider expone los getters de sesión
/// como **shims que delegan** en [SessionManager] (fuente única de verdad).
/// Además reenvía las notificaciones de [SessionManager] para que los `watch`
/// existentes sobre `LoginProvider` sigan siendo reactivos.
///
/// Getters/métodos RETIRADOS de este provider respecto de la versión anterior:
/// - `updateProfile()` -> movido a `ProfileProvider` (features/profile).
/// - `_userPassword` (credencial en texto plano en RAM) -> ELIMINADO.
/// - Los setters/estado de sesión propios (`setAuthToken`/`clearAuthToken` de
///   ApiClient) -> ya no existen; su efecto lo cubren
///   `SessionManager.saveFromLogin` / `SessionManager.clear`.
class LoginProvider with ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final SessionManager _session;

  LoginProvider({
    required LoginUseCase loginUseCase,
    required SessionManager session,
  })  : _loginUseCase = loginUseCase,
        _session = session {
    // Reenvía cambios de sesión a los consumidores de LoginProvider (shim de
    // compatibilidad hasta migrar las páginas a SessionManager).
    _session.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _session.removeListener(notifyListeners);
    super.dispose();
  }

  LoginStatus _status = LoginStatus.initial;
  String? _errorMessage;

  // ---- Estado del formulario de login ----
  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == LoginStatus.loading;

  // ---- Shims de sesión (delegan en SessionManager; TEMPORAL) ----
  String? get token => _session.token;
  String? get role => _session.role;
  int? get userId => _session.userId;
  int? get patientId => _session.patientId;
  int? get doctorId => _session.doctorId;
  int? get medicalRecordId => _session.medicalRecordId;
  int? get receptionistId => _session.receptionistId;
  String? get subscriptionStatus => _session.subscriptionStatus;
  UserProfile? get userProfile => _session.userProfile;
  bool get isDoctor => _session.isDoctor;
  bool get needsSubscriptionGate => _session.needsSubscriptionGate;
  String get name => _session.name;
  String get lastName => _session.lastName;
  String get email => _session.email;
  String get fullName => _session.fullName;

  /// Puente register -> login. Delega en [SessionManager.setPatientId].
  void setPatientId(int id) => _session.setPatientId(id);

  Future<bool> login(String email, String password) async {
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase.execute(request);
      // AWAIT obligatorio: login_page/register_page leen role y
      // needsSubscriptionGate inmediatamente después de que login() resuelve.
      await _session.saveFromLogin(response);

      _status = LoginStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = LoginStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logout. Delega el teardown de sesión en [SessionManager.clear] (que limpia
  /// memoria + notifica de forma síncrona) y resetea solo el estado del form.
  void reset() {
    _session.clear();
    _status = LoginStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}