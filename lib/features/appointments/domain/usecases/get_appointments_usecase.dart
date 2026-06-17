import '../../data/models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository repository;

  const GetAppointmentsUseCase({required this.repository});

  Future<List<AppointmentModel>> execute() {
    return repository.getAppointments();
  }
}
