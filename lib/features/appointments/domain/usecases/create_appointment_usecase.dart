import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class CreateAppointmentUsecase {
  final AppointmentRepository _repository;

  const CreateAppointmentUsecase(this._repository);

  Future<void> call(Appointment appointment) {
    return _repository.createAppointment(appointment);
  }
}
