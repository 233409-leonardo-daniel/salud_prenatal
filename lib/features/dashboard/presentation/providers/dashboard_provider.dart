import 'package:flutter/foundation.dart';
import '../../data/models/medical_record_response.dart';
import '../../data/models/consultation_response.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_patients_by_doctor_usecase.dart';
import '../../domain/usecases/get_medical_record_by_patient_usecase.dart';
import '../../domain/usecases/get_consultations_by_medical_record_usecase.dart';
import '../../domain/usecases/get_consultations_from_patient_endpoint_usecase.dart';
import '../../domain/usecases/get_patient_dashboard_usecase.dart';
import '../../domain/usecases/create_medical_record_usecase.dart';
import '../pages/dashboard_state.dart';

class DashboardProvider with ChangeNotifier {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final GetPatientsByDoctorUseCase _getPatientsByDoctorUseCase;
  final GetMedicalRecordByPatientUseCase _getMedicalRecordByPatientUseCase;
  final GetConsultationsByMedicalRecordUseCase _getConsultationsByMedicalRecordUseCase;
  final GetConsultationsFromPatientEndpointUseCase _getConsultationsFromPatientEndpointUseCase;
  final GetPatientDashboardUseCase _getPatientDashboardUseCase;
  final CreateMedicalRecordUseCase _createMedicalRecordUseCase;

  DashboardProvider({
    required GetAllUsersUseCase getAllUsersUseCase,
    required GetPatientsByDoctorUseCase getPatientsByDoctorUseCase,
    required GetMedicalRecordByPatientUseCase getMedicalRecordByPatientUseCase,
    required GetConsultationsByMedicalRecordUseCase getConsultationsByMedicalRecordUseCase,
    required GetConsultationsFromPatientEndpointUseCase getConsultationsFromPatientEndpointUseCase,
    required GetPatientDashboardUseCase getPatientDashboardUseCase,
    required CreateMedicalRecordUseCase createMedicalRecordUseCase,
  })  : _getAllUsersUseCase = getAllUsersUseCase,
        _getPatientsByDoctorUseCase = getPatientsByDoctorUseCase,
        _getMedicalRecordByPatientUseCase = getMedicalRecordByPatientUseCase,
        _getConsultationsByMedicalRecordUseCase = getConsultationsByMedicalRecordUseCase,
        _getConsultationsFromPatientEndpointUseCase = getConsultationsFromPatientEndpointUseCase,
        _getPatientDashboardUseCase = getPatientDashboardUseCase,
        _createMedicalRecordUseCase = createMedicalRecordUseCase;

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

  CriticalPatientsStatus _criticalPatientsStatus = CriticalPatientsStatus.initial;
  List<Map<String, dynamic>> _criticalPatients = [];

  DashboardStatus get status => _status;
  DashboardDetailsStatus get detailsStatus => _detailsStatus;
  SaveRecordStatus get saveStatus => _saveStatus;
  CriticalPatientsStatus get criticalPatientsStatus => _criticalPatientsStatus;
  bool get isCriticalPatientsLoading => _criticalPatientsStatus == CriticalPatientsStatus.loading;
  List<Map<String, dynamic>> get criticalPatients => _criticalPatients;

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
      _users = await _getAllUsersUseCase.call();
      _patients = await _getPatientsByDoctorUseCase.call(doctorId);
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
      _users = await _getAllUsersUseCase.call();

      try {
        _dashboardData = await _getPatientDashboardUseCase.call(patientId);
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
        _medicalRecord = await _getMedicalRecordByPatientUseCase.call(patientId, doctorId: doctorId ?? 0);
      } catch (e) {
        print('Error fetching medical record: $e');
        _medicalRecord = null;
      }

      if (_medicalRecord != null) {
        _consultations = await _getConsultationsByMedicalRecordUseCase.call(
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
      _activeMedicalRecord = await _getMedicalRecordByPatientUseCase.call(patientId, doctorId: doctorId ?? 0);
      if (_activeMedicalRecord != null) {
        _activeConsultations = await _getConsultationsFromPatientEndpointUseCase.call(patientId, doctorId: doctorId ?? 0);
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
      final record = await _createMedicalRecordUseCase.call(recordData);
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

  /// Carga los pacientes con riesgo alto/crítico para el doctor indicado.
  /// Parte de la lista de pacientes del doctor (ya cargada en `_patients` vía
  /// GET /doctors/{doctor_id}/patients) y consulta en paralelo (Future.wait)
  /// el expediente + predicción de riesgo de cada uno vía
  /// GET /medical-records/patient/{patient_id}?doctor_id={doctor_id}.
  Future<void> loadCriticalPatients(int doctorId) async {
    final patientIds = _patients
        .map((p) => p['patient_id'])
        .whereType<int>()
        .toSet()
        .toList();

    if (patientIds.isEmpty) {
      _criticalPatients = [];
      _criticalPatientsStatus = CriticalPatientsStatus.success;
      notifyListeners();
      return;
    }

    _criticalPatientsStatus = CriticalPatientsStatus.loading;
    notifyListeners();

    try {
      final results = await Future.wait(
        patientIds.map(
          (pid) => _getMedicalRecordByPatientUseCase
              .call(pid, doctorId: doctorId)
              .catchError((_) => null),
        ),
      );

      final critical = <Map<String, dynamic>>[];
      for (final record in results) {
        if (record == null) continue;
        final diagnosis = record.riskPrediction?.diagnosis;
        if (diagnosis == null || diagnosis.isEmpty) continue;

        final lower = diagnosis.toLowerCase();
        final isHighRisk = lower.contains('alto') ||
            lower.contains('crítico') ||
            lower.contains('critico');
        if (!isHighRisk) continue;

        final fullName = '${record.name ?? ''} ${record.lastName ?? ''}'.trim();
        critical.add({
          'patientId': record.patientId,
          'name': fullName.isNotEmpty ? fullName : 'Paciente #${record.patientId}',
          'diagnosis': diagnosis,
          'riskCluster': record.riskPrediction?.riskCluster,
        });
      }

      _criticalPatients = critical;
      _criticalPatientsStatus = CriticalPatientsStatus.success;
    } catch (e) {
      print('Error al cargar pacientes críticos: $e');
      _criticalPatientsStatus = CriticalPatientsStatus.error;
    } finally {
      notifyListeners();
    }
  }
}
