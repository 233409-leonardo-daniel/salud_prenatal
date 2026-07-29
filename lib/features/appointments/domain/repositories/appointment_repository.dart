import '../entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointmentsByUserId(String userId, {bool isDoctor = false});
  Future<List<Appointment>> getAppointments({int? doctorId, int? patientId, String? status, String? date});
  Future<Appointment> getAppointmentById(int id);
  Future<void> createAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> updateAppointmentStatus(int id, AppointmentStatus status);
  Future<void> deleteAppointment(int id);
}
