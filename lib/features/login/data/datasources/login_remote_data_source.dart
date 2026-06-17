import '../models/login_request.dart';

abstract class LoginRemoteDataSource {
  /// Sends login credentials to the backend. Returns a token or success response.
  Future<String> login(LoginRequest request);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  @override
  Future<String> login(LoginRequest request) async {
    // Simulate API network latency
    await Future.delayed(const Duration(seconds: 2));

    // Simple mock logic for testing the skeleton
    if (request.email == 'test@example.com' && request.password == 'password123') {
      return 'mock_jwt_token_12345';
    } else if (request.email.contains('@')) {
      return 'mock_jwt_token_generic';
    } else {
      throw Exception('Credenciales inválidas');
    }
  }
}
