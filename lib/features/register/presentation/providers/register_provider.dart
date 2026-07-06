import 'package:flutter/foundation.dart';
import '../../data/models/register_request.dart';
import '../../domain/usecases/register_usecase.dart';
import '../pages/register_state.dart';

class RegisterProvider with ChangeNotifier {
  final RegisterPatientUseCase _registerPatientUseCase;
  final RegisterDoctorUseCase _registerDoctorUseCase;
  final RegisterReceptionistUseCase _registerReceptionistUseCase;

  RegisterProvider({
    required RegisterPatientUseCase registerPatientUseCase,
    required RegisterDoctorUseCase registerDoctorUseCase,
    required RegisterReceptionistUseCase registerReceptionistUseCase,
  })  : _registerPatientUseCase = registerPatientUseCase,
        _registerDoctorUseCase = registerDoctorUseCase,
        _registerReceptionistUseCase = registerReceptionistUseCase;

  String _selectedRole = 'patient'; // 'patient' | 'doctor'
  String get selectedRole => _selectedRole;

  RegisterStatus _status = RegisterStatus.initial;
  RegisterStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _token;
  String? get token => _token;

  int? _lastRegisteredPatientId;
  int? get lastRegisteredPatientId => _lastRegisteredPatientId;

  /// Compatibilidad con código que usa [isLoading] directamente.
  bool get isLoading => _status == RegisterStatus.loading;

  void setRole(String role) {
    if (_selectedRole != role) {
      _selectedRole = role;
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> registerPatient({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String birthdate,
    required String bloodType,
    required int weeksAtRegistration,
    required String lastMenstrualPeriod,
    required String residence,
  }) async {
    _status = RegisterStatus.loading;
    _errorMessage = null;
    _token = null;
    _lastRegisteredPatientId = null;
    notifyListeners();

    try {
      final request = PatientRegisterRequest(
        name: name,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        birthdate: birthdate,
        bloodType: bloodType,
        weeksAtRegistration: weeksAtRegistration,
        lastMenstrualPeriod: lastMenstrualPeriod,
        residence: residence,
      );
      final result = await _registerPatientUseCase.execute(request);
      _token = result['access_token']?.toString() ?? result['token']?.toString() ?? 'success';
      _lastRegisteredPatientId = result['patient_id'] as int?;
      _status = RegisterStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = RegisterStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDoctor({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String professionalLicense,
    required String specialty,
    required String office,
  }) async {
    _status = RegisterStatus.loading;
    _errorMessage = null;
    _token = null;
    notifyListeners();

    try {
      final request = DoctorRegisterRequest(
        name: name,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        professionalLicense: professionalLicense,
        specialty: specialty,
        office: office,
      );
      _token = await _registerDoctorUseCase.execute(request);
      _status = RegisterStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = RegisterStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerReceptionist({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required int doctorId,
  }) async {
    _status = RegisterStatus.loading;
    _errorMessage = null;
    _token = null;
    notifyListeners();

    try {
      final request = ReceptionistRegisterRequest(
        name: name,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      _token = await _registerReceptionistUseCase.execute(request, doctorId);
      _status = RegisterStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = RegisterStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAdmin({
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = RegisterStatus.loading;
    _errorMessage = null;
    _token = null;
    notifyListeners();

    try {
      throw Exception('El registro de administrador no está disponible en la API.');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = RegisterStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = RegisterStatus.initial;
    _errorMessage = null;
    _token = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
