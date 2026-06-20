import '../entities/patient_diary.dart';
import '../repositories/patient_diary_repository.dart';

class GetDiariesByMedicalRecordUseCase {
  final PatientDiaryRepository _repository;

  GetDiariesByMedicalRecordUseCase(this._repository);

  Future<List<PatientDiary>> execute(int medicalRecordId) {
    return _repository.getDiariesByMedicalRecord(medicalRecordId);
  }
}
