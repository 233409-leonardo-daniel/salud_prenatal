import '../entities/patient_diary.dart';
import '../repositories/patient_diary_repository.dart';

class CreatePatientDiaryUsecase {
  final PatientDiaryRepository _repository;

  CreatePatientDiaryUsecase(this._repository);

  Future<PatientDiary> execute(PatientDiary diary) {
    return _repository.createPatientDiary(diary);
  }
}
