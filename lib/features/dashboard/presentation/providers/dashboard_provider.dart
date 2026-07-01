import 'package:flutter/foundation.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/models/medical_record_response.dart';
import '../../data/models/consultation_response.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../pages/dashboard_state.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardProvider({required DashboardRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardDetailsStatus _detailsStatus = DashboardDetailsStatus.initial;
  SaveRecordStatus _saveStatus = SaveRecordStatus.initial;
  String? _errorMessage;
  List<UserProfile> _users = [];
  List<Map<String, dynamic>> _patients = [];
  MedicalRecordResponse? _medicalRecord;
  List<ConsultationResponse> _consultations = [];
  Map<String, dynamic>? _currentPatientData;
  Map<String, dynamic>? _dashboardData;

  MedicalRecordResponse? _activeMedicalRecord;
  List<ConsultationResponse> _activeConsultations = [];

  DashboardStatus get status => _status;
  DashboardDetailsStatus get detailsStatus => _detailsStatus;
  SaveRecordStatus get saveStatus => _saveStatus;

  bool get isLoading => _status == DashboardStatus.loading;
  bool get isDetailsLoading => _detailsStatus == DashboardDetailsStatus.loading;
  bool get isSavingRecord => _saveStatus == SaveRecordStatus.loading;
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
    _status = DashboardStatus.loading;
    _errorMessage = null;
    _users = [];
    _patients = [];
    _medicalRecord = null;
    _consultations = [];
    _dashboardData = null;
    _currentPatientData = null;
    notifyListeners();

    try {
      _users = await _remoteDataSource.getAllUsers();
      _patients = await _remoteDataSource.getPatientsByDoctor(doctorId);
      _status = DashboardStatus.success;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadPatientDashboard(int patientId, int userId, {int? doctorId}) async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    _medicalRecord = null;
    _consultations = [];
    _dashboardData = null;
    _currentPatientData = null;
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
        _medicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId, doctorId: doctorId ?? 0);
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
      _status = DashboardStatus.success;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadPatientDetails(int patientId, {int? doctorId}) async {
    _detailsStatus = DashboardDetailsStatus.loading;
    _activeMedicalRecord = null;
    _activeConsultations = [];
    notifyListeners();

    try {
      _activeMedicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId, doctorId: doctorId ?? 0);
      if (_activeMedicalRecord != null) {
        _activeConsultations = await _remoteDataSource.getConsultationsFromPatientEndpoint(patientId, doctorId: doctorId ?? 0);
      }
      _detailsStatus = DashboardDetailsStatus.success;
    } catch (e) {
      print('Error al cargar detalles de paciente: $e');
      _detailsStatus = DashboardDetailsStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createMedicalRecord(Map<String, dynamic> recordData) async {
    _saveStatus = SaveRecordStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = await _remoteDataSource.createMedicalRecord(recordData);
      _activeMedicalRecord = record;
      _activeConsultations = [];
      _saveStatus = SaveRecordStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _saveStatus = SaveRecordStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      notifyListeners();
    }
  }
}
