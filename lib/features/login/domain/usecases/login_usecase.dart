import '../../data/models/login_request.dart';
import '../entities/login_response.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../repositories/login_repository.dart';

class LoginUsecase {
  final LoginRepository repository;

  const LoginUsecase({required this.repository});

  Future<LoginResponse> execute(LoginRequest request) {
    return repository.login(request);
  }
}

class GetProfileUsecase {
  final LoginRepository repository;

  const GetProfileUsecase({required this.repository});

  Future<UserProfile> execute(int userId, {int? doctorId}) {
    return repository.getUserProfile(userId, doctorId: doctorId);
  }
}
