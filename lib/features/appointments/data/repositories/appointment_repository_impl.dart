import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_data_source.dart';
import '../models/appointment_model.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  const AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AppointmentModel>> getAppointments() {
    return remoteDataSource.getAppointments();
  }
}
