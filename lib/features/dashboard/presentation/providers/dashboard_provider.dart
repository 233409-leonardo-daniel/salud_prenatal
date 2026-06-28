import 'package:flutter/foundation.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/models/medical_record_response.dart';
import '../../data/models/consultation_response.dart';
import '../../../login/domain/entities/user_profile.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardProvider({DashboardRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? DashboardRemoteDataSourceImpl();

  bool _isLoading = false;
  bool _isDetailsLoading = false;
  bool _isSavingRecord = false;
  String? _errorMessage;
  List<UserProfile> _users = [];
  List<Map<String, dynamic>> _patients = [];
  MedicalRecordResponse? _medicalRecord;
  List<ConsultationResponse> _consultations = [];
  Map<String, dynamic>? _currentPatientData;
  Map<String, dynamic>? _dashboardData;

  MedicalRecordResponse? _activeMedicalRecord;
  List<ConsultationResponse> _activeConsultations = [];

  bool get isLoading => _isLoading;
  bool get isDetailsLoading => _isDetailsLoading;
  bool get isSavingRecord => _isSavingRecord;
  String? get errorMessage => _errorMessage;
  List<UserProfile> get users => _users;
  List<Map<String, dynamic>> get patients => _patients;
  MedicalRecordResponse? get medicalRecord => _medicalRecord;
  List<ConsultationResponse> get consultations => _consultations;
  Map<String, dynamic>? get currentPatientData => _currentPatientData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  MedicalRecordResponse? get activeMedicalRecord => _activeMedicalRecord;
  List<ConsultationResponse> get activeConsultations => _activeConsultations;

  Future<void> loadDoctorDashboard(int doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _remoteDataSource.getAllUsers();
      _patients = await _remoteDataSource.getPatientsByDoctor(doctorId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientDashboard(int patientId, int userId, {int? doctorId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _remoteDataSource.getAllUsers();

      try {
        _dashboardData = await _remoteDataSource.getPatientDashboard(patientId);
        _currentPatientData = {
          'patient_id': patientId,
          'user_id': userId,
          'current_gestational_weeks': _dashboardData?['current_gestational_weeks'] ?? 28,
        };
      } catch (e) {
        print('Error fetching patient dashboard: $e');
        _currentPatientData = {
          'patient_id': patientId,
          'user_id': userId,
          'current_gestational_weeks': 28,
        };
      }

      try {
        _medicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId, doctorId: doctorId);
      } catch (e) {
        print('Error fetching medical record: $e');
        _medicalRecord = null;
      }

      if (_medicalRecord != null) {
        _consultations = await _remoteDataSource.getConsultationsByMedicalRecord(
          _medicalRecord!.medicalRecordId,
        );
      } else {
        _consultations = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatientDetails(int patientId, {int? doctorId}) async {
    _isDetailsLoading = true;
    _activeMedicalRecord = null;
    _activeConsultations = [];
    notifyListeners();

    try {
      _activeMedicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId, doctorId: doctorId);
      if (_activeMedicalRecord != null) {
        _activeConsultations = await _remoteDataSource.getConsultationsByMedicalRecord(
          _activeMedicalRecord!.medicalRecordId,
        );
      }
    } catch (e) {
      print('Error al cargar detalles de paciente: $e');
    } finally {
      _isDetailsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMedicalRecord(Map<String, dynamic> recordData) async {
    _isSavingRecord = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = await _remoteDataSource.createMedicalRecord(recordData);
      _activeMedicalRecord = record;
      _activeConsultations = [];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSavingRecord = false;
      notifyListeners();
    }
  }
}
