import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:salud_prenatal/core/session/session_manager.dart';
import 'package:salud_prenatal/features/login/domain/entities/login_response.dart';
import 'package:salud_prenatal/features/login/domain/entities/user_profile.dart';

/// Canal de método real de flutter_secure_storage; se mockea con un mapa en
/// memoria para poder ejercitar la persistencia del token sin plataforma.
const MethodChannel _secureChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

UserProfile _profile({String role = 'paciente'}) => UserProfile(
      userId: 1,
      name: 'Ana',
      lastName: 'Pérez',
      email: 'ana@example.com',
      role: role,
    );

LoginResponse _response({
  String role = 'paciente',
  String? subscriptionStatus,
  int userId = 1,
  int? patientId,
  int? doctorId,
  int? medicalRecordId,
  int? receptionistId,
}) =>
    LoginResponse(
      accessToken: 'jwt-token-abc',
      tokenType: 'bearer',
      userId: userId,
      role: role,
      patientId: patientId,
      doctorId: doctorId,
      medicalRecordId: medicalRecordId,
      receptionistId: receptionistId,
      subscriptionStatus: subscriptionStatus,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureStore;

  setUp(() {
    secureStore = <String, String>{};
    SharedPreferences.setMockInitialValues(<String, Object>{});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureChannel, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          final value = args['value'] as String?;
          if (value == null) {
            secureStore.remove(key);
          } else {
            secureStore[key!] = value;
          }
          return null;
        case 'read':
          return secureStore[key];
        case 'delete':
          secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        case 'containsKey':
          return secureStore.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureChannel, null);
  });

  group('isDoctor / needsSubscriptionGate', () {
    test('doctor con suscripción inactiva necesita el gate', () async {
      final session = SessionManager();
      await session.saveFromLogin(
        _response(role: 'doctor', subscriptionStatus: 'inactive'),
      );

      expect(session.isDoctor, isTrue);
      expect(session.needsSubscriptionGate, isTrue);
    });

    test('doctor(a) también cuenta como doctor', () async {
      final session = SessionManager();
      await session.saveFromLogin(
        _response(role: 'doctor(a)', subscriptionStatus: 'active'),
      );

      expect(session.isDoctor, isTrue);
      expect(session.needsSubscriptionGate, isFalse);
    });

    test('doctor sin subscriptionStatus no dispara el gate (guarda null)',
        () async {
      final session = SessionManager();
      await session.saveFromLogin(
        _response(role: 'doctor', subscriptionStatus: null),
      );

      expect(session.needsSubscriptionGate, isFalse);
    });

    test('paciente nunca necesita el gate', () async {
      final session = SessionManager();
      await session.saveFromLogin(
        _response(role: 'paciente', subscriptionStatus: 'inactive'),
      );

      expect(session.isDoctor, isFalse);
      expect(session.needsSubscriptionGate, isFalse);
    });
  });

  group('saveFromLogin', () {
    test('puebla token, ids de paciente y perfil vía loader', () async {
      final session = SessionManager()
        ..attachProfileLoader((_) async => _profile());

      var notified = 0;
      session.addListener(() => notified++);

      await session.saveFromLogin(
        _response(
          role: 'paciente',
          userId: 7,
          patientId: 42,
          doctorId: 3,
          medicalRecordId: 99,
        ),
      );

      expect(session.token, 'jwt-token-abc');
      expect(session.isAuthenticated, isTrue);
      expect(session.userId, 7);
      expect(session.patientId, 42);
      expect(session.doctorId, 3);
      expect(session.medicalRecordId, 99);
      expect(session.userProfile?.email, 'ana@example.com');
      expect(notified, greaterThan(0));
    });

    test('doctor deja medicalRecordId y receptionistId en null', () async {
      final session = SessionManager();
      await session.saveFromLogin(
        _response(
          role: 'doctor',
          doctorId: 5,
          medicalRecordId: 99,
          receptionistId: 8,
        ),
      );

      expect(session.doctorId, 5);
      expect(session.medicalRecordId, isNull);
      expect(session.receptionistId, isNull);
    });

    test('preserva el patientId de setPatientId cuando el response no trae uno',
        () async {
      final session = SessionManager()..setPatientId(123);

      await session.saveFromLogin(_response(role: 'paciente', patientId: null));

      expect(session.patientId, 123);
    });

    test('perfil null cuando el loader falla, pero la sesión sigue válida',
        () async {
      final session = SessionManager()
        ..attachProfileLoader((_) async => throw Exception('red caída'));

      await session.saveFromLogin(_response(role: 'paciente'));

      expect(session.userProfile, isNull);
      expect(session.isAuthenticated, isTrue);
    });
  });

  group('clear', () {
    test('anula todo el estado y marca no autenticado', () async {
      final session = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      await session.saveFromLogin(
        _response(role: 'paciente', patientId: 42),
      );

      await session.clear();

      expect(session.token, isNull);
      expect(session.role, isNull);
      expect(session.userId, isNull);
      expect(session.patientId, isNull);
      expect(session.userProfile, isNull);
      expect(session.isAuthenticated, isFalse);
    });

    test('borra el token del secure storage', () async {
      final session = SessionManager();
      await session.saveFromLogin(_response(role: 'paciente'));
      expect(secureStore['session.token'], isNotNull);

      await session.clear();

      expect(secureStore['session.token'], isNull);
    });
  });

  group('restore', () {
    test('sin token persistido devuelve false', () async {
      final session = SessionManager();
      expect(await session.restore(), isFalse);
    });

    test('restaura escalares y perfil desde disco', () async {
      // Persistir con una primera instancia.
      final first = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      await first.saveFromLogin(
        _response(role: 'paciente', userId: 7, patientId: 42),
      );

      // Nueva instancia arranca en frío y restaura.
      final second = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      final ok = await second.restore();

      expect(ok, isTrue);
      expect(second.token, 'jwt-token-abc');
      expect(second.userId, 7);
      expect(second.patientId, 42);
      expect(second.role, 'paciente');
      expect(second.userProfile?.email, 'ana@example.com');
    });

    test(
        'la inactividad ya no descarta la sesión (se quitó el logout automático)',
        () async {
      final first = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      await first.saveFromLogin(_response(role: 'paciente', userId: 7));

      // Ya no existe una guarda de inactividad en restore(): un timestamp
      // de "última actividad" viejo (heredado de una versión anterior de la
      // app, o de la extinta SessionTimeoutListener) no debe afectar nada.
      final prefs = await SharedPreferences.getInstance();
      final stale = DateTime.now()
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch;
      await prefs.setInt('last_activity_timestamp', stale);

      final second = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      final ok = await second.restore();

      expect(ok, isTrue);
      expect(second.isAuthenticated, isTrue);
    });

    test('sonda de liveness fallida descarta la sesión', () async {
      final first = SessionManager()
        ..attachProfileLoader((_) async => _profile());
      await first.saveFromLogin(_response(role: 'paciente', userId: 7));

      final second = SessionManager()
        ..attachProfileLoader((_) async => throw Exception('401'));
      final ok = await second.restore();

      expect(ok, isFalse);
      expect(second.isAuthenticated, isFalse);
      expect(secureStore['session.token'], isNull);
    });
  });
}
