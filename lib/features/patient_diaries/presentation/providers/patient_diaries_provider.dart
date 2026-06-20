import 'package:flutter/foundation.dart';
import '../../domain/entities/patient_diary.dart';
import '../../domain/usecases/create_patient_diary_usecase.dart';
import '../../domain/usecases/delete_patient_diary_usecase.dart';
import '../../domain/usecases/get_patient_diaries_usecase.dart';
import '../../domain/usecases/update_patient_diary_usecase.dart';

enum PatientDiariesStatus { initial, loading, success, error }

class PatientDiariesProvider with ChangeNotifier {
  final GetDiariesByMedicalRecordUseCase _getDiariesUseCase;
  final CreatePatientDiaryUseCase _createDiaryUseCase;
  final UpdatePatientDiaryUseCase _updateDiaryUseCase;
  final DeletePatientDiaryUseCase _deleteDiaryUseCase;

  PatientDiariesProvider({
    required GetDiariesByMedicalRecordUseCase getDiariesUseCase,
    required CreatePatientDiaryUseCase createDiaryUseCase,
    required UpdatePatientDiaryUseCase updateDiaryUseCase,
    required DeletePatientDiaryUseCase deleteDiaryUseCase,
  })  : _getDiariesUseCase = getDiariesUseCase,
        _createDiaryUseCase = createDiaryUseCase,
        _updateDiaryUseCase = updateDiaryUseCase,
        _deleteDiaryUseCase = deleteDiaryUseCase;

  PatientDiariesStatus _status = PatientDiariesStatus.initial;
  String? _errorMessage;
  List<PatientDiary> _diaries = [];

  PatientDiariesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PatientDiary> get diaries => _diaries;

  bool get isLoading => _status == PatientDiariesStatus.loading;

  Future<void> loadDiaries(int medicalRecordId) async {
    _status = PatientDiariesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _diaries = await _getDiariesUseCase.execute(medicalRecordId);
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
