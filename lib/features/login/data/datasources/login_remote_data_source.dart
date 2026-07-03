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
    final response = await _apiClient.post(
      '/users/login',
      {
        'email': request.email,
        'password': request.password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
  }

  @override
  Future<UserProfile> getUserProfile(int userId) async {
    final response = await _apiClient.get('/users/$userId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    }
    throw Exception('Error al obtener perfil (Status: ${response.statusCode})');
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile) async {
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
  }
}
