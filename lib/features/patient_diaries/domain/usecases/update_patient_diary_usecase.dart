import '../entities/patient_diary.dart';
import '../repositories/patient_diary_repository.dart';

class UpdatePatientDiaryUseCase {
  final PatientDiaryRepository _repository;

  UpdatePatientDiaryUseCase(this._repository);

  Future<PatientDiary> execute({
    required int patientDiaryId,
    required double weightKg,
    required int systolic,
    required int diastolic,
    required String symptoms,
    required String notes,
  }) {
    return _repository.updatePatientDiary(
      patientDiaryId,
      weightKg,
      systolic,
      diastolic,
      symptoms,
      notes,
    );
  }
}
