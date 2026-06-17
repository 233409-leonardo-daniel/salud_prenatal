import '../../data/models/login_request.dart';
import '../repositories/login_repository.dart';

class LoginUseCase {
  final LoginRepository repository;

  const LoginUseCase({required this.repository});

  Future<String> execute(LoginRequest request) {
    return repository.login(request);
  }
}
