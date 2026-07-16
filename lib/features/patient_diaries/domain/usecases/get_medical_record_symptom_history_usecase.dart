import '../entities/aggregated_symptom.dart';
import '../repositories/patient_diary_repository.dart';

class GetMedicalRecordSymptomHistoryUseCase {
  final PatientDiaryRepository repository;

  GetMedicalRecordSymptomHistoryUseCase(this.repository);

  Future<List<AggregatedSymptom>> execute(int medicalRecordId) {
    return repository.getMedicalRecordSymptomHistory(medicalRecordId);
  }
}
