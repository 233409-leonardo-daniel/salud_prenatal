import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class UpdateAppointmentUsecase {
  final AppointmentRepository _repository;

  const UpdateAppointmentUsecase(this._repository);

  Future<void> call(Appointment appointment) {
    return _repository.updateAppointment(appointment);
  }
}
