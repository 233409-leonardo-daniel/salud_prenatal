import 'package:flutter/material.dart';
import '../../data/datasources/register_remote_data_source.dart';
import '../../data/models/register_request.dart';
import '../../data/repositories/register_repository_impl.dart';
import '../../domain/usecases/register_usecase.dart';

class RegisterProvider extends ChangeNotifier {
  final RegisterPatientUseCase _registerPatientUseCase;
  final RegisterDoctorUseCase _registerDoctorUseCase;

  RegisterProvider({
    RegisterPatientUseCase? registerPatientUseCase,
    RegisterDoctorUseCase? registerDoctorUseCase,
  })  : _registerPatientUseCase = registerPatientUseCase ??
            RegisterPatientUseCase(
              repository: RegisterRepositoryImpl(
                remoteDataSource: RegisterRemoteDataSourceImpl(),
              ),
            ),
        _registerDoctorUseCase = registerDoctorUseCase ??
            RegisterDoctorUseCase(
              repository: RegisterRepositoryImpl(
                remoteDataSource: RegisterRemoteDataSourceImpl(),
              ),
            );

  String _selectedRole = 'patient'; // 'patient', 'doctor', 'admin'
  String get selectedRole => _selectedRole;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _token;
  String? get token => _token;

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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _token = null;
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
      );
      _token = await _registerPatientUseCase.execute(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
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
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
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
    _isLoading = true;
    _errorMessage = null;
    _token = null;
    notifyListeners();

    try {
      // Admin is general user registration
      await Future.delayed(const Duration(seconds: 2));
      _token = 'mock_admin_token_xyz123';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
