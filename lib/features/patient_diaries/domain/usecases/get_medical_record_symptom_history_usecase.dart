import '../entities/aggregated_symptom.dart';
import '../repositories/patient_diary_repository.dart';

class GetMedicalRecordSymptomHistoryUsecase {
  final PatientDiaryRepository repository;

  GetMedicalRecordSymptomHistoryUsecase(this.repository);

  Future<List<AggregatedSymptom>> execute(int medicalRecordId) {
    return repository.getMedicalRecordSymptomHistory(medicalRecordId);
  }
}
