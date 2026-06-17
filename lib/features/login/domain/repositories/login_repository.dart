import '../../data/models/login_request.dart';
import '../../data/models/login_response.dart';

abstract class LoginRepository {
  Future<LoginResponse> login(LoginRequest request);
}
