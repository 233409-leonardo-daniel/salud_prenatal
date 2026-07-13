import '../entities/extracted_symptom.dart';
import '../repositories/patient_diary_repository.dart';

class GetDiarySymptomsUseCase {
  final PatientDiaryRepository repository;

  GetDiarySymptomsUseCase(this.repository);

  Future<List<ExtractedSymptom>> execute(int patientDiaryId) {
    return repository.getDiarySymptoms(patientDiaryId);
  }
}
