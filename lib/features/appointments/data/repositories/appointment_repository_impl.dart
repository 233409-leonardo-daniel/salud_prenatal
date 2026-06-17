import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  const AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Appointment>> getAppointments() async {
    final models = await remoteDataSource.getAppointments();
    // Return models implicitly casted as their superclass (Appointment entity)
    return models;
  }
}
