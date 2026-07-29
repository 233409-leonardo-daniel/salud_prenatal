import '../../domain/repositories/patients_repository.dart';
import '../../domain/entities/patient.dart';
import '../datasources/patients_remote_data_source.dart';
import '../../../profile/domain/entities/user_profile.dart';

class PatientsRepositoryImpl implements PatientsRepository {
  final PatientsRemoteDataSource remoteDataSource;

  PatientsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PatientEntity>> getPatientsByDoctor(String doctorId) async {
    return await remoteDataSource.getPatientsByDoctor(doctorId);
  }

  @override
  Future<UserProfile> getPatientDetails(String userId) async {
    return await remoteDataSource.getPatientDetails(userId);
  }
}
