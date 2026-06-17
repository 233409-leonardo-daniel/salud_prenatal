import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_data_source.dart';
import '../models/login_request.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  const LoginRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> login(LoginRequest request) {
    return remoteDataSource.login(request);
  }
}
