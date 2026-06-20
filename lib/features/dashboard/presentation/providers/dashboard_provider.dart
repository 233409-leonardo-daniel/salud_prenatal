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
  String? _errorMessage;
  List<UserProfile> _users = [];
  List<Map<String, dynamic>> _patients = [];
  MedicalRecordResponse? _medicalRecord;
  List<ConsultationResponse> _consultations = [];
  Map<String, dynamic>? _currentPatientData;

  MedicalRecordResponse? _activeMedicalRecord;
  List<ConsultationResponse> _activeConsultations = [];

  bool get isLoading => _isLoading;
  bool get isDetailsLoading => _isDetailsLoading;
  String? get errorMessage => _errorMessage;
  List<UserProfile> get users => _users;
  List<Map<String, dynamic>> get patients => _patients;
  MedicalRecordResponse? get medicalRecord => _medicalRecord;
  List<ConsultationResponse> get consultations => _consultations;
  Map<String, dynamic>? get currentPatientData => _currentPatientData;

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

  Future<void> loadPatientDashboard(int patientId, int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _remoteDataSource.getAllUsers();
      _medicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId);

      final patientsList = await _remoteDataSource.getPatientsByDoctor(1);
      final match = patientsList.firstWhere(
        (p) => p['patient_id'] == patientId || p['user_id'] == userId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        _currentPatientData = match;
      } else {
        _currentPatientData = {
          'patient_id': patientId,
          'user_id': userId,
          'current_gestational_weeks': 28, // Default fallback
        };
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

  Future<void> loadPatientDetails(int patientId) async {
    _isDetailsLoading = true;
    _activeMedicalRecord = null;
    _activeConsultations = [];
    notifyListeners();

    try {
      _activeMedicalRecord = await _remoteDataSource.getMedicalRecordByPatient(patientId);
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
}
