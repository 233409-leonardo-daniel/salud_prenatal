import 'package:flutter/foundation.dart';
import '../../data/models/login_request.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../pages/login_state.dart';
import '../../../../core/network/api_client.dart';

class LoginProvider with ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  LoginProvider({
    required LoginUseCase loginUseCase,
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  })  : _loginUseCase = loginUseCase,
        _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase;

  LoginStatus _status = LoginStatus.initial;
  String? _errorMessage;
  String? _token;
  String? _role;
  int? _userId;
  int? _patientId;
  int? _doctorId;
  int? _medicalRecordId;
  UserProfile? _userProfile;
  String? _userPassword;

  LoginStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  int? get patientId => _patientId;
  int? get doctorId => _doctorId;
  int? get medicalRecordId => _medicalRecordId;
  UserProfile? get userProfile => _userProfile;

  void setPatientId(int id) {
    _patientId = id;
    notifyListeners();
  }

  String get name => _userProfile?.name ?? '';
  String get lastName => _userProfile?.lastName ?? '';
  String get fullName => '$name $lastName'.trim();

  /// Compatibilidad con código que usa [isLoading] directamente.
  bool get isLoading => _status == LoginStatus.loading;

  Future<bool> login(String email, String password) async {
    // Guardar patientId previo (del registro) antes de resetear
    final savedPatientId = _patientId;
    _status = LoginStatus.loading;
    _errorMessage = null;
    _token = null;
    _role = null;
    _userId = null;
    _patientId = savedPatientId; // Conservar si viene del registro
    _doctorId = null;
    _medicalRecordId = null;
    _userProfile = null;
    _userPassword = password;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _loginUseCase.execute(request);
      _token = response.accessToken;
      ApiClient().setAuthToken(response.accessToken);
      _role = response.role;
      _userId = response.userId;

      final isDoctor = _role == 'doctor' || _role == 'doctor(a)';
      if (isDoctor) {
        _doctorId = response.doctorId ?? 1; // Default doctor ID fallback
      } else {
        // Assign patientId from response directly.
        // Also keep previousPatientId logic if we came from registration and the API login doesn't have it yet, 
        // though the new backend should return it.
        _patientId = response.patientId ?? _patientId ?? _userId; 
        _doctorId = response.doctorId;
        _medicalRecordId = response.medicalRecordId;
      }

      try {
        _userProfile = await _getProfileUseCase.execute(response.userId);
      } catch (e) {
        print('Error al obtener perfil de usuario de la API: $e');
        // Fallback offline con datos compatibles con el mockup
        _userProfile = UserProfile(
          name: isDoctor ? 'Lucía' : 'Ana',
          lastName: isDoctor ? 'Mendoza' : 'García',
          email: email,
          role: _role ?? 'paciente',
        );
      }

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

  void reset() {
    _status = LoginStatus.initial;
    _errorMessage = null;
    _token = null;
    _role = null;
    _userId = null;
    _patientId = null;
    _doctorId = null;
    _medicalRecordId = null;
    _userProfile = null;
    _userPassword = null;
    ApiClient().clearAuthToken();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String lastName,
    required String phone,
    String? email,
    String? imageUrl,
  }) async {
    if (_userId == null) {
      _errorMessage = 'Usuario no autenticado';
      notifyListeners();
      return false;
    }
    _status = LoginStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = UserProfile(
        userId: _userId,
        name: name,
        lastName: lastName,
        email: email ?? _userProfile?.email ?? '',
        role: _userProfile?.role ?? 'paciente',
        phone: phone,
        imageUrl: imageUrl ?? _userProfile?.imageUrl ?? '',
        isActive: _userProfile?.isActive ?? true,
        createdAt: _userProfile?.createdAt ?? '',
        updatedAt: _userProfile?.updatedAt ?? '',
        password: _userPassword,
      );
      
      _userProfile = await _updateProfileUseCase.execute(_userId!, updatedProfile);
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
}
