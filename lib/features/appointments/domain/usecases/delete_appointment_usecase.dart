import '../repositories/appointment_repository.dart';

class DeleteAppointmentUsecase {
  final AppointmentRepository _repository;

  const DeleteAppointmentUsecase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteAppointment(id);
  }
}
