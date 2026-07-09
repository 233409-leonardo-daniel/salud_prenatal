import '../../data/models/login_request.dart';
import '../entities/login_response.dart';
import '../entities/user_profile.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  final LoginRepository repository;

  const LoginUseCase({required this.repository});

  Future<LoginResponse> execute(LoginRequest request) {
    return repository.login(request);
  }
}

class GetProfileUseCase {
  final LoginRepository repository;

  const GetProfileUseCase({required this.repository});

  Future<UserProfile> execute(int userId) {
    return repository.getUserProfile(userId);
  }
}
