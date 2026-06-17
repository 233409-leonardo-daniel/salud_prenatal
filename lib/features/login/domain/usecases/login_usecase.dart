import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  final LoginRepository repository;

  const LoginUseCase({required this.repository});

  Future<LoginResponse> execute(LoginRequest request) {
    return repository.login(request);
  }
}
