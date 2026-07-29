import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_data_source.dart';
import '../models/login_request.dart';
import '../../domain/entities/login_response.dart';
import '../../../profile/domain/entities/user_profile.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource remoteDataSource;

  const LoginRepositoryImpl({required this.remoteDataSource});

  @override
  Future<LoginResponse> login(LoginRequest request) {
    return remoteDataSource.login(request);
  }

  @override
  Future<UserProfile> getUserProfile(int userId, {int? doctorId}) {
    return remoteDataSource.getUserProfile(userId, doctorId: doctorId);
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile, {int? doctorId}) {
    return remoteDataSource.updateUserProfile(userId, profile, doctorId: doctorId);
  }
}
