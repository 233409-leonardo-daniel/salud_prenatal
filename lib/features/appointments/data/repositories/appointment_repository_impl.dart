import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  const AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Appointment>> getAppointmentsByUserId(String userId) async {
    final models = await remoteDataSource.getAppointmentsByUserId(userId);
    return models;
  }

  @override
  Future<void> createAppointment(Appointment appointment) {
    return remoteDataSource.createAppointment(appointment);
  }

  @override
  Future<void> updateAppointment(Appointment appointment) {
    return remoteDataSource.updateAppointment(appointment);
  }

  @override
  Future<void> deleteAppointment(String id) {
    return remoteDataSource.deleteAppointment(id);
  }
}
