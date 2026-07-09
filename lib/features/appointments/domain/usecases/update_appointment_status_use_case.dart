import '../../../../core/enums/appointment_status.dart';
import '../repositories/appointment_repository.dart';

class UpdateAppointmentStatusUseCase {
  final AppointmentRepository repository;

  UpdateAppointmentStatusUseCase(this.repository);

  Future<void> call(int id, AppointmentStatus status) async {
    return await repository.updateAppointmentStatus(id, status);
  }
}
