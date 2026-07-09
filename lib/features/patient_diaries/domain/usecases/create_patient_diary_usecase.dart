import '../entities/patient_diary.dart';
import '../repositories/patient_diary_repository.dart';

class CreatePatientDiaryUseCase {
  final PatientDiaryRepository _repository;

  CreatePatientDiaryUseCase(this._repository);

  Future<PatientDiary> execute(PatientDiary diary) {
    return _repository.createPatientDiary(diary);
  }
}
