import '../../data/models/login_request.dart';
import '../entities/login_response.dart';
import '../../../profile/domain/entities/user_profile.dart';

abstract class LoginRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<UserProfile> getUserProfile(int userId, {int? doctorId});
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile, {int? doctorId});
}
