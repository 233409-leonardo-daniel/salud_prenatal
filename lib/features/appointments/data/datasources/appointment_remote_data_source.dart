import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointments();
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  @override
  Future<List<AppointmentModel>> getAppointments() async {
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
        dateTime: DateTime.now().add(const Duration(days: 15, hours: -3)),
        status: AppointmentStatus.pending,
        reason: 'Ecografía morfológica',
      ),
      AppointmentModel(
        id: '3',
        doctorName: 'Dra. Mendoza',
        patientName: 'Ana García',
        dateTime: DateTime.now().subtract(const Duration(days: 30, hours: 1)),
        status: AppointmentStatus.completed,
        reason: 'Primera consulta prenatal',
      ),
    ];
  }
}
