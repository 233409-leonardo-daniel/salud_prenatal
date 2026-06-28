import '../repositories/appointment_repository.dart';

class CheckAvailabilityUseCase {
  final AppointmentRepository repository;

  CheckAvailabilityUseCase(this.repository);

  Future<Map<String, dynamic>> call(int doctorId, String date) async {
    return await repository.checkAvailability(doctorId, date);
  }
}
