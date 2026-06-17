import '../../data/models/appointment_model.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentModel>> getAppointments();
}
