import '../entities/patient_diary.dart';
import '../entities/extracted_symptom.dart';
import '../entities/aggregated_symptom.dart';

abstract class PatientDiaryRepository {
  Future<List<PatientDiary>> getDiariesByMedicalRecord(int medicalRecordId);
  Future<PatientDiary> createPatientDiary(PatientDiary diary);
  Future<PatientDiary> updatePatientDiary(
    int patientDiaryId,
    double weightKg,
    int systolic,
    int diastolic,
    String symptoms,
    String notes,
  );
  Future<void> deletePatientDiary(int patientDiaryId);
  Future<List<ExtractedSymptom>> getDiarySymptoms(int patientDiaryId);
  Future<List<AggregatedSymptom>> getMedicalRecordSymptomHistory(int medicalRecordId);
}
