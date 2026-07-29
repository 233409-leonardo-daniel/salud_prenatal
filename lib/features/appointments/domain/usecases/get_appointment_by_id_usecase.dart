import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentByIdUsecase {
  final AppointmentRepository repository;

  GetAppointmentByIdUsecase(this.repository);

  Future<Appointment> call(int id) async {
    return await repository.getAppointmentById(id);
  }
}
