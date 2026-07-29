import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class UpdateAppointmentStatusUsecase {
  final AppointmentRepository repository;

  UpdateAppointmentStatusUsecase(this.repository);

  Future<void> call(int id, AppointmentStatus status) async {
    return await repository.updateAppointmentStatus(id, status);
  }
}
