import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/entities/user_profile.dart';
import '../models/login_request.dart';

abstract class LoginRemoteDataSource {
  /// Sends login credentials to the backend. Returns LoginResponse.
  Future<LoginResponse> login(LoginRequest request);
  Future<UserProfile> getUserProfile(int userId);
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final ApiClient _apiClient;

  LoginRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/users/login',
        {
          'email': request.email,
          'password': request.password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('====== LOGIN RESPONSE CREDENTIALS ======');
        print(response.body);
        print('========================================');
        return LoginResponse.fromJson(data);
      }
      
      // Procesar mensajes de error si falló la conexión pero el server respondió
      final errorBody = response.body;
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

  @override
  Future<UserProfile> getUserProfile(int userId) async {
    try {
      final response = await _apiClient.get('/users/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
      throw Exception('Error al obtener perfil (Status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') || 
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(seconds: 1));
        final String role = userId == 99 ? 'doctor' : 'paciente';
        return UserProfile(
          userId: userId,
          name: role == 'doctor' ? 'Lucía' : 'Ana',
          lastName: role == 'doctor' ? 'Mendoza' : 'García',
          email: role == 'doctor' ? 'doctor@example.com' : 'paciente@example.com',
          role: role,
          phone: role == 'doctor' ? '9611234567' : '9617654321',
          imageUrl: '',
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile) async {
    try {
      final response = await _apiClient.put(
        '/users/$userId',
        profile.toJson(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }

      String errorMsg = 'Error al actualizar perfil (Status: ${response.statusCode})';
      try {
        final errorJson = jsonDecode(response.body);
        final detail = errorJson['detail'];
        if (detail is String) {
          errorMsg = detail;
        } else if (detail is List && detail.isNotEmpty) {
          errorMsg = detail.map((e) {
            final loc = e['loc'] is List ? e['loc'].join('.') : 'campo';
            final msg = e['msg'] ?? 'inválido';
            return "$loc: $msg";
          }).join('\n');
        } else if (errorJson['message'] != null) {
          errorMsg = errorJson['message'];
        }
      } catch (_) {}

      throw Exception(errorMsg);
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') || 
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(seconds: 1));
        return profile;
      }
      rethrow;
    }
  }
}
