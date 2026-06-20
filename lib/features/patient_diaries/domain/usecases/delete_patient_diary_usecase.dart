import '../repositories/patient_diary_repository.dart';

class DeletePatientDiaryUseCase {
  final PatientDiaryRepository _repository;

  DeletePatientDiaryUseCase(this._repository);

  Future<void> execute(int patientDiaryId) {
    return _repository.deletePatientDiary(patientDiaryId);
  }
}
