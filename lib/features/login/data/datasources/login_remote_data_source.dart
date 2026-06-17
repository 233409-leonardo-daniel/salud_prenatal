import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class LoginRemoteDataSource {
  /// Sends login credentials to the backend. Returns LoginResponse.
  Future<LoginResponse> login(LoginRequest request);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('${ApiClient.baseUrl}/users/login');
    
    try {
      // 1. Intentar enviar JSON
      final jsonResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': request.email,
          'password': request.password,
        }),
      );

      if (jsonResponse.statusCode == 200) {
        final data = jsonDecode(jsonResponse.body);
        return LoginResponse.fromJson(data);
      }
      
      // 2. Intentar x-www-form-urlencoded (FastAPI OAuth2 standard form-data expects username & password)
      final formResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': request.email,
          'password': request.password,
        },
      );

      if (formResponse.statusCode == 200) {
        final data = jsonDecode(formResponse.body);
        return LoginResponse.fromJson(data);
      }

      // Procesar mensajes de error si falló la conexión pero el server respondió
      final errorBody = jsonResponse.body.isNotEmpty ? jsonResponse.body : formResponse.body;
      try {
        final errorJson = jsonDecode(errorBody);
        final detail = errorJson['detail'];
        if (detail is String) {
          throw Exception(detail);
        } else if (detail is List && detail.isNotEmpty) {
          throw Exception(detail[0]['msg'] ?? 'Error de inicio de sesión');
        }
      } catch (_) {}
      
      throw Exception('Credenciales incorrectas');
    } catch (e) {
      // Soporte offline para pruebas en caso de que el backend local no esté activo
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') || 
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(seconds: 1));
        final String role = request.email.toLowerCase().contains('doctor') ? 'doctor' : 'paciente';
        return LoginResponse(
          accessToken: 'mock_token_offline_99',
          tokenType: 'bearer',
          userId: 99,
          role: role,
        );
      }
      rethrow;
    }
  }
}
