import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsByUserIdUsecase {
  final AppointmentRepository _repository;

  const GetAppointmentsByUserIdUsecase(this._repository);

  Future<List<Appointment>> call(String userId) {
    return _repository.getAppointmentsByUserId(userId);
  }
}
