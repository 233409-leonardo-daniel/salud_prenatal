import '../../data/models/login_request.dart';
import '../entities/login_response.dart';
import '../entities/user_profile.dart';

abstract class LoginRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<UserProfile> getUserProfile(int userId);
}
