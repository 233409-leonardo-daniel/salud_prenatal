import 'package:flutter/foundation.dart';
import '../../domain/entities/patient_diary.dart';
import '../../domain/entities/extracted_symptom.dart';
import '../../domain/entities/aggregated_symptom.dart';
import '../../domain/usecases/create_patient_diary_usecase.dart';
import '../../domain/usecases/delete_patient_diary_usecase.dart';
import '../../domain/usecases/get_patient_diaries_usecase.dart';
import '../../domain/usecases/update_patient_diary_usecase.dart';
import '../../domain/usecases/get_diary_symptoms_usecase.dart';
import '../../domain/usecases/get_medical_record_symptom_history_usecase.dart';

enum PatientDiariesStatus { initial, loading, success, error }

class PatientDiariesProvider with ChangeNotifier {
  final GetDiariesByMedicalRecordUsecase _getDiariesUseCase;
  final CreatePatientDiaryUsecase _createDiaryUseCase;
  final UpdatePatientDiaryUsecase _updateDiaryUseCase;
  final DeletePatientDiaryUsecase _deleteDiaryUseCase;
  final GetDiarySymptomsUsecase _getDiarySymptomsUseCase;
  final GetMedicalRecordSymptomHistoryUsecase _getSymptomHistoryUseCase;

  PatientDiariesProvider({
    required GetDiariesByMedicalRecordUsecase getDiariesUseCase,
    required CreatePatientDiaryUsecase createDiaryUseCase,
    required UpdatePatientDiaryUsecase updateDiaryUseCase,
    required DeletePatientDiaryUsecase deleteDiaryUseCase,
    required GetDiarySymptomsUsecase getDiarySymptomsUseCase,
    required GetMedicalRecordSymptomHistoryUsecase getSymptomHistoryUseCase,
  })  : _getDiariesUseCase = getDiariesUseCase,
        _createDiaryUseCase = createDiaryUseCase,
        _updateDiaryUseCase = updateDiaryUseCase,
        _deleteDiaryUseCase = deleteDiaryUseCase,
        _getDiarySymptomsUseCase = getDiarySymptomsUseCase,
        _getSymptomHistoryUseCase = getSymptomHistoryUseCase;

  PatientDiariesStatus _status = PatientDiariesStatus.initial;
  String? _errorMessage;
  List<PatientDiary> _diaries = [];

  // Síntomas detectados por bitácora (§1.3) — cacheados por patientDiaryId
  // para no repetir la llamada si el usuario colapsa/expande la misma
  // entrada varias veces.
  final Map<int, List<ExtractedSymptom>> _diarySymptoms = {};
  final Set<int> _loadingDiarySymptoms = {};

  // Historial agregado de síntomas del embarazo (§1.4).
  PatientDiariesStatus _symptomHistoryStatus = PatientDiariesStatus.initial;
  List<AggregatedSymptom> _symptomHistory = [];

  PatientDiariesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PatientDiary> get diaries => _diaries;

  bool get isLoading => _status == PatientDiariesStatus.loading;

  List<ExtractedSymptom>? symptomsForDiary(int patientDiaryId) => _diarySymptoms[patientDiaryId];
  bool isLoadingSymptomsFor(int patientDiaryId) => _loadingDiarySymptoms.contains(patientDiaryId);

  PatientDiariesStatus get symptomHistoryStatus => _symptomHistoryStatus;
  List<AggregatedSymptom> get symptomHistory => _symptomHistory;

  /// Trae los síntomas detectados por el NLP en UNA bitácora (lazy, con
  /// caché en memoria). Lista vacía `[]` es un resultado normal (nada
  /// detectado o NLP no disponible), no un error.
  Future<void> loadDiarySymptoms(int patientDiaryId) async {
    if (_diarySymptoms.containsKey(patientDiaryId) || _loadingDiarySymptoms.contains(patientDiaryId)) {
      return;
    }
    _loadingDiarySymptoms.add(patientDiaryId);
    notifyListeners();

    try {
      _diarySymptoms[patientDiaryId] = await _getDiarySymptomsUseCase.execute(patientDiaryId);
    } catch (e) {
      debugPrint('Error loading diary symptoms for $patientDiaryId: $e');
      _diarySymptoms[patientDiaryId] = [];
    } finally {
      _loadingDiarySymptoms.remove(patientDiaryId);
      notifyListeners();
    }
  }

  /// Historial agregado de síntomas de todo el embarazo (botón "ver
  /// historial completo" en el expediente/bitácora).
  Future<void> loadSymptomHistory(int medicalRecordId) async {
    _symptomHistoryStatus = PatientDiariesStatus.loading;
    notifyListeners();

    try {
      _symptomHistory = await _getSymptomHistoryUseCase.execute(medicalRecordId);
      _symptomHistoryStatus = PatientDiariesStatus.success;
    } catch (e) {
      debugPrint('Error loading symptom history for $medicalRecordId: $e');
      _symptomHistoryStatus = PatientDiariesStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadDiaries(int medicalRecordId) async {
    _status = PatientDiariesStatus.loading;
    _errorMessage = null;
    _diaries = [];
    notifyListeners();

    try {
      final allDiaries = await _getDiariesUseCase.execute(medicalRecordId);
      _diaries = allDiaries;
      // Sort: newest first
      _diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _status = PatientDiariesStatus.success;
    } catch (e) {
      _status = PatientDiariesStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createDiary({
    required int medicalRecordId,
    required double weightKg,
    required int systolic,
    required int diastolic,
    required String symptoms,
    required String notes,
  }) async {
    _status = PatientDiariesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final newDiary = PatientDiary(
        patientDiaryId: 0,
        medicalRecordId: medicalRecordId,
        weightKg: weightKg,
        systolic: systolic,
        diastolic: diastolic,
        symptoms: symptoms,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final created = await _createDiaryUseCase.execute(newDiary);
      _diaries.insert(0, created);
      _status = PatientDiariesStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PatientDiariesStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDiary({
    required int patientDiaryId,
    required double weightKg,
    required int systolic,
    required int diastolic,
    required String symptoms,
    required String notes,
  }) async {
    _status = PatientDiariesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _updateDiaryUseCase.execute(
        patientDiaryId: patientDiaryId,
        weightKg: weightKg,
        systolic: systolic,
        diastolic: diastolic,
        symptoms: symptoms,
        notes: notes,
      );

      final index = _diaries.indexWhere((d) => d.patientDiaryId == patientDiaryId);
      if (index != -1) {
        _diaries[index] = updated;
      }
      _status = PatientDiariesStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PatientDiariesStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDiary(int patientDiaryId) async {
    _status = PatientDiariesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _deleteDiaryUseCase.execute(patientDiaryId);
      _diaries.removeWhere((d) => d.patientDiaryId == patientDiaryId);
      _status = PatientDiariesStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PatientDiariesStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
