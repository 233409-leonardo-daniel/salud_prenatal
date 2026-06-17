import '../../domain/repositories/register_repository.dart';
import '../datasources/register_remote_data_source.dart';
import '../models/register_request.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDataSource remoteDataSource;

  const RegisterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> registerPatient(PatientRegisterRequest request) {
    return remoteDataSource.registerPatient(request);
  }

  @override
  Future<String> registerDoctor(DoctorRegisterRequest request) {
    return remoteDataSource.registerDoctor(request);
  }
}
