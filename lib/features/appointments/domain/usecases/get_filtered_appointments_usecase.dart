import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetFilteredAppointmentsUsecase {
  final AppointmentRepository repository;

  GetFilteredAppointmentsUsecase(this.repository);

  Future<List<Appointment>> call({int? doctorId, int? patientId, String? status, String? date}) async {
    return await repository.getAppointments(
      doctorId: doctorId,
      patientId: patientId,
      status: status,
      date: date,
    );
  }
}
