import 'package:flutter/foundation.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../../patients/domain/entities/patient.dart';
import '../../../patients/domain/usecases/get_doctor_patients_usecase.dart';
import '../../../dashboard/domain/usecases/get_all_users_usecase.dart';

enum ContactsStatus { initial, loading, success, error }

/// Arma la lista de "con quién se puede empezar a chatear" (pacientes del
/// doctor + médicos, si es recepcionista) para el diálogo de "nuevo
/// contacto" del chat. Vive en `chat` (es la única pantalla que la usa) pero
/// reutiliza los usecases de `patients` y `dashboard` en vez de duplicar sus
/// llamadas a la API.
///
/// GET /doctors/{id}/patients ya devuelve `full_name` por paciente (ver
/// [PatientEntity.fullName]), así que para un doctor alcanza con esa sola
/// llamada. GET /users/ solo se pide si [loadContacts] recibe
/// `isReceptionist: true` — es la única forma de listar médicos (con quiénes
/// también puede chatear una recepcionista), no hay endpoint de "solo
/// doctores".
///
/// El status arranca en [ContactsStatus.initial] y pasa a `loading` de forma
/// síncrona (antes de cualquier `await`), así la UI que lo observa siempre
/// tiene un estado explícito desde el primer frame — no depende del timing
/// de un `Future` guardado aparte, que es lo que causaba la pantalla en
/// negro al abrir el diálogo directamente.
class ContactsProvider with ChangeNotifier {
  final GetDoctorPatientsUseCase _getDoctorPatientsUseCase;
  final GetAllUsersUseCase _getAllUsersUseCase;

  ContactsProvider(this._getDoctorPatientsUseCase, this._getAllUsersUseCase);

  ContactsStatus _status = ContactsStatus.initial;
  List<UserProfile> _contacts = [];
  String? _errorMessage;

  ContactsStatus get status => _status;
  List<UserProfile> get contacts => _contacts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContactsStatus.loading;

  Future<void> loadContacts(int doctorId, {required bool isReceptionist}) async {
    _status = ContactsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Si es recepcionista, arrancar /users/ ya mismo (en paralelo con
      // /doctors/{id}/patients) en vez de esperar a necesitarlo.
      final usersFuture = isReceptionist ? _getAllUsersUseCase.call() : null;
      final patients = await _getDoctorPatientsUseCase.call(doctorId.toString());

      final result = <UserProfile>[
        for (final patient in patients) _patientToContact(patient),
      ];

      if (usersFuture != null) {
        final users = await usersFuture;
        result.addAll(users.where((u) => u.role.toLowerCase().contains('doctor')));
      }

      _contacts = result;
      _status = ContactsStatus.success;
    } catch (e) {
      _status = ContactsStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  UserProfile _patientToContact(PatientEntity patient) {
    final parts = (patient.fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return UserProfile(userId: patient.userId, name: 'Paciente', lastName: '${patient.patientId}', email: '', role: 'paciente');
    }
    return UserProfile(
      userId: patient.userId,
      name: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      email: '',
      role: 'paciente',
    );
  }
}
