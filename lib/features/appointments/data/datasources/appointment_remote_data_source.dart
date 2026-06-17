import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointmentsByUserId(String userId);
  Future<void> createAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  @override
  Future<List<AppointmentModel>> getAppointmentsByUserId(String userId) async {
    // Simulate API network latency
    await Future.delayed(const Duration(seconds: 1));

    // Mock data for appointments
    return [
      AppointmentModel(
        id: '1',
        doctorName: 'Dra. Mendoza',
        patientName: 'Ana García',
        dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        status: AppointmentStatus.pending,
        reason: 'Control mensual de embarazo',
      ),
      AppointmentModel(
        id: '2',
        doctorName: 'Dr. Pérez',
        patientName: 'Ana García',
        dateTime: DateTime.now().add(const Duration(days: 15)),
        status: AppointmentStatus.pending,
        reason: 'Ecografía morfológica',
      ),
      AppointmentModel(
        id: '3',
        doctorName: 'Dra. Mendoza',
        patientName: 'Ana García',
        dateTime: DateTime.now().subtract(const Duration(days: 30)),
        status: AppointmentStatus.completed,
        reason: 'Primera consulta prenatal',
      ),
    ];
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock: no-op for now
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock: no-op for now
  }

  @override
  Future<void> deleteAppointment(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: no-op for now
  }
}
