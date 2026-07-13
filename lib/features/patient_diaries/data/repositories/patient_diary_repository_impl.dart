import '../../domain/entities/patient_diary.dart';
import '../../domain/entities/extracted_symptom.dart';
import '../../domain/entities/aggregated_symptom.dart';
import '../../domain/repositories/patient_diary_repository.dart';
import '../datasources/patient_diary_remote_data_source.dart';

class PatientDiaryRepositoryImpl implements PatientDiaryRepository {
  final PatientDiaryRemoteDataSource remoteDataSource;

  PatientDiaryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PatientDiary>> getDiariesByMedicalRecord(int medicalRecordId) {
    return remoteDataSource.getDiariesByMedicalRecord(medicalRecordId);
  }

  @override
  Future<PatientDiary> createPatientDiary(PatientDiary diary) {
    return remoteDataSource.createPatientDiary(diary);
  }

  @override
  Future<PatientDiary> updatePatientDiary(
    int patientDiaryId,
    double weightKg,
    int systolic,
    int diastolic,
    String symptoms,
    String notes,
  ) {
    return remoteDataSource.updatePatientDiary(
      patientDiaryId,
      weightKg,
      systolic,
      diastolic,
      symptoms,
      notes,
    );
  }

  @override
  Future<void> deletePatientDiary(int patientDiaryId) {
    return remoteDataSource.deletePatientDiary(patientDiaryId);
  }

  @override
  Future<List<ExtractedSymptom>> getDiarySymptoms(int patientDiaryId) {
    return remoteDataSource.getDiarySymptoms(patientDiaryId);
  }

  @override
  Future<List<AggregatedSymptom>> getMedicalRecordSymptomHistory(int medicalRecordId) {
    return remoteDataSource.getMedicalRecordSymptomHistory(medicalRecordId);
  }
}
