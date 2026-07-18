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
import '../../domain/usecases/get_doctor_dashboard_usecase.dart';
import '../../domain/usecases/get_receptionist_dashboard_usecase.dart';
import '../../domain/usecases/create_medical_record_usecase.dart';
import '../../domain/usecases/evaluate_risk_usecase.dart';
import '../../domain/usecases/create_consultation_usecase.dart';
import '../pages/dashboard_state.dart';

class DashboardProvider with ChangeNotifier {
  final GetAllUsersUseCase _getAllUsersUseCase;
  final GetPatientsByDoctorUseCase _getPatientsByDoctorUseCase;
  final GetMedicalRecordByPatientUseCase _getMedicalRecordByPatientUseCase;
  final GetConsultationsByMedicalRecordUseCase _getConsultationsByMedicalRecordUseCase;
  final GetConsultationsFromPatientEndpointUseCase _getConsultationsFromPatientEndpointUseCase;
  final GetPatientDashboardUseCase _getPatientDashboardUseCase;
  final GetDoctorDashboardUseCase _getDoctorDashboardUseCase;
  final GetReceptionistDashboardUseCase _getReceptionistDashboardUseCase;
  final CreateMedicalRecordUseCase _createMedicalRecordUseCase;
  final EvaluateRiskUseCase _evaluateRiskUseCase;
  final CreateConsultationUseCase _createConsultationUseCase;

  DashboardProvider({
    required GetAllUsersUseCase getAllUsersUseCase,
    required GetPatientsByDoctorUseCase getPatientsByDoctorUseCase,
    required GetMedicalRecordByPatientUseCase getMedicalRecordByPatientUseCase,
    required GetConsultationsByMedicalRecordUseCase getConsultationsByMedicalRecordUseCase,
    required GetConsultationsFromPatientEndpointUseCase getConsultationsFromPatientEndpointUseCase,
    required GetPatientDashboardUseCase getPatientDashboardUseCase,
    required GetDoctorDashboardUseCase getDoctorDashboardUseCase,
    required GetReceptionistDashboardUseCase getReceptionistDashboardUseCase,
    required CreateMedicalRecordUseCase createMedicalRecordUseCase,
    required EvaluateRiskUseCase evaluateRiskUseCase,
    required CreateConsultationUseCase createConsultationUseCase,
  })  : _getAllUsersUseCase = getAllUsersUseCase,
        _getPatientsByDoctorUseCase = getPatientsByDoctorUseCase,
        _getMedicalRecordByPatientUseCase = getMedicalRecordByPatientUseCase,
        _getConsultationsByMedicalRecordUseCase = getConsultationsByMedicalRecordUseCase,
        _getConsultationsFromPatientEndpointUseCase = getConsultationsFromPatientEndpointUseCase,
        _getPatientDashboardUseCase = getPatientDashboardUseCase,
        _getDoctorDashboardUseCase = getDoctorDashboardUseCase,
        _getReceptionistDashboardUseCase = getReceptionistDashboardUseCase,
        _createMedicalRecordUseCase = createMedicalRecordUseCase,
        _evaluateRiskUseCase = evaluateRiskUseCase,
        _createConsultationUseCase = createConsultationUseCase;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardDetailsStatus _detailsStatus = DashboardDetailsStatus.initial;
  SaveRecordStatus _saveStatus = SaveRecordStatus.initial;
  RiskEvaluationStatus _riskEvaluationStatus = RiskEvaluationStatus.initial;
  String? _errorMessage;
  List<UserProfile> _users = [];
  List<Map<String, dynamic>> _patients = [];
  MedicalRecordResponse? _medicalRecord;
  Map<String, dynamic>? _doctorDashboardData;
  Map<String, dynamic>? _receptionistDashboardData;
  List<ConsultationResponse> _consultations = [];
  Map<String, dynamic>? _currentPatientData;
  Map<String, dynamic>? _dashboardData;

  MedicalRecordResponse? _activeMedicalRecord;
  List<ConsultationResponse> _activeConsultations = [];

  CriticalPatientsStatus _criticalPatientsStatus = CriticalPatientsStatus.initial;
  List<Map<String, dynamic>> _criticalPatients = [];

  bool _isCreatingConsultation = false;
  bool get isCreatingConsultation => _isCreatingConsultation;

  DashboardStatus get status => _status;
  DashboardDetailsStatus get detailsStatus => _detailsStatus;
  SaveRecordStatus get saveStatus => _saveStatus;
  CriticalPatientsStatus get criticalPatientsStatus => _criticalPatientsStatus;
  bool get isCriticalPatientsLoading => _criticalPatientsStatus == CriticalPatientsStatus.loading;
  List<Map<String, dynamic>> get criticalPatients => _criticalPatients;

  bool get isLoading => _status == DashboardStatus.loading;
  bool get isDetailsLoading => _detailsStatus == DashboardDetailsStatus.loading;
  bool get isSavingRecord => _saveStatus == SaveRecordStatus.loading;
  RiskEvaluationStatus get riskEvaluationStatus => _riskEvaluationStatus;
  bool get isEvaluatingRisk => _riskEvaluationStatus == RiskEvaluationStatus.loading;
  String? get errorMessage => _errorMessage;
  List<UserProfile> get users => _users;
  List<Map<String, dynamic>> get patients => _patients;
  MedicalRecordResponse? get medicalRecord => _medicalRecord;
  List<ConsultationResponse> get consultations => _consultations;
  Map<String, dynamic>? get currentPatientData => _currentPatientData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  MedicalRecordResponse? get activeMedicalRecord => _activeMedicalRecord;
  List<ConsultationResponse> get activeConsultations => _activeConsultations;
  Map<String, dynamic>? get doctorDashboardData => _doctorDashboardData;

  /// GET /doctors/receptionists/{receptionist_id}/dashboard — nombre de la
  /// recepcionista + citas del doctor asignado, ya filtradas/ordenadas por
  /// el backend.
  Map<String, dynamic>? get receptionistDashboardData => _receptionistDashboardData;
  String get receptionistFullName => _receptionistDashboardData?['full_name'] as String? ?? '';
  List<Map<String, dynamic>> get receptionistUpcomingAppointments =>
      (_receptionistDashboardData?['upcoming_appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get receptionistPendingAppointments =>
      (_receptionistDashboardData?['pending_appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get receptionistConfirmedAppointments =>
      (_receptionistDashboardData?['confirmed_appointments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  Future<void> loadDoctorDashboard(int doctorId) async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    _doctorDashboardData = null;
    notifyListeners();

    try {
      _doctorDashboardData = await _getDoctorDashboardUseCase.call(doctorId);
      _status = DashboardStatus.success;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  /// GET /doctors/receptionists/{receptionist_id}/dashboard — usado por el
  /// dashboard de la recepcionista en vez de AppointmentsProvider.
  Future<void> loadReceptionistDashboard(int receptionistId) async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    _receptionistDashboardData = null;
    notifyListeners();

    try {
      _receptionistDashboardData = await _getReceptionistDashboardUseCase.call(receptionistId);
      _status = DashboardStatus.success;
    } catch (e) {
      print('Error al cargar dashboard de la recepcionista: $e');
      _status = DashboardStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadDoctorPatients(int doctorId) async {
    try {
      _patients = await _getPatientsByDoctorUseCase.call(doctorId);
      _users = await _getAllUsersUseCase.call();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar pacientes/usuarios del doctor: $e');
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
      // La lista completa de usuarios solo se usa para resolver el nombre del
      // doctor en el botón de chat; se carga en segundo plano para NO bloquear
      // el render del dashboard de la paciente (ese endpoint es pesado).
      _loadUsersInBackground();

      try {
        _dashboardData = await _getPatientDashboardUseCase.call(patientId);
        _currentPatientData = {
          'patient_id': patientId,
          'user_id': userId,
          'current_gestational_weeks': _dashboardData?['current_gestational_weeks'],
        };
      } catch (e) {
        print('Error fetching patient dashboard: $e');
        _currentPatientData = {
          'patient_id': patientId,
          'user_id': userId,
          'current_gestational_weeks': null,
        };
      }

      if (doctorId != null) {
        try {
          _medicalRecord = await _getMedicalRecordByPatientUseCase.call(patientId, doctorId: doctorId);
        } catch (e) {
          print('Error fetching medical record: $e');
          _medicalRecord = null;
        }
      } else {
        // Sin doctorId no podemos pedir el expediente (la API lo exige); no
        // inventamos uno para no consultar el expediente de otro doctor.
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

  /// Marca el dashboard en error (p. ej. sesión incompleta, sin userId o sin
  /// doctorId). Evita que la pantalla se quede en el spinner para siempre.
  void setSessionError(String message) {
    _status = DashboardStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Carga la lista de usuarios en segundo plano (no crítica para el render).
  /// Si falla o tarda, el dashboard ya se mostró de todos modos.
  Future<void> _loadUsersInBackground() async {
    try {
      _users = await _getAllUsersUseCase.call();
      notifyListeners();
    } catch (e) {
      print('Error cargando lista de usuarios (no crítico): $e');
    }
  }

  /// Versión liviana de [loadPatientDashboard] para pantallas que solo
  /// necesitan el nombre del doctor asignado (`current_doctor`) y la lista
  /// de usuarios para resolver su user_id — sin expediente médico ni
  /// consultas (evita golpear /medical-records y /consultations cuando no
  /// se van a mostrar, p. ej. la bandeja de chat).
  Future<void> loadPatientBasicInfo(int patientId) async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _getAllUsersUseCase.call();
      _dashboardData = await _getPatientDashboardUseCase.call(patientId);
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
      if (doctorId == null) {
        // Sin doctorId no podemos pedir el expediente (la API lo exige); no
        // inventamos uno para no consultar el expediente de otro doctor.
        _activeMedicalRecord = null;
        _activeConsultations = [];
        _detailsStatus = DashboardDetailsStatus.success;
        return;
      }
      _activeMedicalRecord = await _getMedicalRecordByPatientUseCase.call(patientId, doctorId: doctorId);
      if (_activeMedicalRecord != null) {
        // GET /consultations/medical-record/{medical_record_id}: fuente de
        // verdad para las consultas del expediente activo (en vez del array
        // `consultations` embebido en /medical-records/patient/{id}).
        _activeConsultations = await _getConsultationsByMedicalRecordUseCase.call(
          _activeMedicalRecord!.medicalRecordId,
        );
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

  /// Dispara la evaluación de riesgo manual (botón "Evaluar riesgo" del
  /// doctor) vía POST /medical-records/{id}/risk-evaluation y refresca
  /// `_activeMedicalRecord` con la nueva predicción sin recargar todo el
  /// expediente.
  Future<bool> evaluateRisk(int medicalRecordId) async {
    _riskEvaluationStatus = RiskEvaluationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final riskPrediction = await _evaluateRiskUseCase.call(medicalRecordId);
      if (_activeMedicalRecord != null && _activeMedicalRecord!.medicalRecordId == medicalRecordId) {
        _activeMedicalRecord = _activeMedicalRecord!.copyWithRiskPrediction(riskPrediction);
      }
      _riskEvaluationStatus = RiskEvaluationStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _riskEvaluationStatus = RiskEvaluationStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Crea una nueva consulta (POST /consultations/) para el expediente
  /// [medicalRecordId]. Si ese expediente es el que está activo en
  /// `_activeMedicalRecord`/`_medicalRecord`, inserta la consulta creada al
  /// inicio de la lista correspondiente para reflejarla de inmediato sin
  /// tener que recargar todo el expediente.
  Future<bool> createConsultation({
    required int medicalRecordId,
    String? notes,
    String? objective,
    String? plan,
    required String reportedFacts,
  }) async {
    _isCreatingConsultation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _createConsultationUseCase.call(
        medicalRecordId: medicalRecordId,
        notes: notes,
        objective: objective,
        plan: plan,
        reportedFacts: reportedFacts,
      );
      if (_activeMedicalRecord != null && _activeMedicalRecord!.medicalRecordId == medicalRecordId) {
        _activeConsultations = [created, ..._activeConsultations];
      }
      if (_medicalRecord != null && _medicalRecord!.medicalRecordId == medicalRecordId) {
        _consultations = [created, ..._consultations];
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isCreatingConsultation = false;
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
        final riskPrediction = record.riskPrediction;
        if (riskPrediction == null || !riskPrediction.isOk) continue;

        final clusterName = riskPrediction.diagnosis;
        if (clusterName == null || clusterName.isEmpty) continue;

        final lower = clusterName.toLowerCase();
        final isHighRisk = lower.contains('alto') ||
            lower.contains('crítico') ||
            lower.contains('critico');
        if (!isHighRisk) continue;

        final fullName = '${record.name ?? ''} ${record.lastName ?? ''}'.trim();
        critical.add({
          'patientId': record.patientId,
          'name': fullName.isNotEmpty ? fullName : 'Paciente #${record.patientId}',
          'diagnosis': clusterName,
          'riskCluster': riskPrediction.riskCluster,
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
