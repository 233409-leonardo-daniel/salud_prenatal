import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository repository;

  const GetAppointmentsUseCase({required this.repository});

  Future<List<Appointment>> execute() {
    return repository.getAppointments();
  }
}
