import '../../data/models/login_request.dart';

abstract class LoginRepository {
  Future<String> login(LoginRequest request);
}
