import '../entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointmentsByUserId(String userId, {bool isDoctor = false});
  Future<void> createAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);
}
