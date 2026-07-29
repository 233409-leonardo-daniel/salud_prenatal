import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/login_response.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../models/login_request.dart';

abstract class LoginRemoteDataSource {
  /// Sends login credentials to the backend. Returns LoginResponse.
  Future<LoginResponse> login(LoginRequest request);
  Future<UserProfile> getUserProfile(int userId, {int? doctorId});
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile, {int? doctorId});
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
  Future<UserProfile> getUserProfile(int userId, {int? doctorId}) async {
    final response = await _apiClient.get('/users/$userId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var profile = UserProfile.fromJson(data);
      
      final isDoc = profile.role.toLowerCase() == 'doctor' || profile.role.toLowerCase() == 'doctor(a)';
      if (isDoc) {
        // El `doctor_id` viene del login (session.doctorId) o del propio
        // /users/{id}. Ya NO se escanea /doctors/1..50: era una ráfaga de
        // hasta 50 peticiones. Si no se conoce el id, se devuelve el perfil
        // base de /users/{id} (nombre/correo) sin el detalle del doctor.
        final int? docId = doctorId ?? data['doctor_id'] ?? data['doctorId'];

        if (docId != null) {
          try {
            final docResponse = await _apiClient.get('/doctors/$docId');
            if (docResponse.statusCode == 200) {
              final docData = jsonDecode(docResponse.body);
              profile = UserProfile(
                userId: profile.userId,
                name: docData['name'] ?? profile.name,
                lastName: docData['last_name'] ?? profile.lastName,
                email: docData['email'] ?? profile.email,
                role: profile.role,
                phone: docData['phone'] ?? profile.phone,
                imageUrl: docData['image_url'] ?? profile.imageUrl,
                isActive: profile.isActive,
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt,
                password: profile.password,
                specialty: docData['specialty'],
                professionalLicense: docData['professional_license'],
                office: docData['office'],
              );
            }
          } catch (e) {
            debugPrint('Error al obtener detalles del doctor $docId: $e');
          }
        }
      }
      return profile;
    }
    throw Exception('Error al obtener perfil (Status: ${response.statusCode})');
  }

  @override
  Future<UserProfile> updateUserProfile(int userId, UserProfile profile, {int? doctorId}) async {
    final response = await _apiClient.put(
      '/users/$userId',
      profile.toJson(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var updated = UserProfile.fromJson(data);
      
      final isDoc = updated.role.toLowerCase() == 'doctor' || updated.role.toLowerCase() == 'doctor(a)';
      if (isDoc) {
        // Sin escaneo /doctors/1..50: se usa el doctor_id conocido (sesión o
        // respuesta). Si no está, se omite el detalle del doctor.
        final int? docId = doctorId ?? data['doctor_id'] ?? data['doctorId'];

        if (docId != null) {
          try {
            final docResponse = await _apiClient.get('/doctors/$docId');
            if (docResponse.statusCode == 200) {
              final docData = jsonDecode(docResponse.body);
              updated = UserProfile(
                userId: updated.userId,
                name: docData['name'] ?? updated.name,
                lastName: docData['last_name'] ?? updated.lastName,
                email: docData['email'] ?? updated.email,
                role: updated.role,
                phone: docData['phone'] ?? updated.phone,
                imageUrl: docData['image_url'] ?? updated.imageUrl,
                isActive: updated.isActive,
                createdAt: updated.createdAt,
                updatedAt: updated.updatedAt,
                password: updated.password,
                specialty: docData['specialty'],
                professionalLicense: docData['professional_license'],
                office: docData['office'],
              );
            }
          } catch (_) {}
        }
      }
      return updated;
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
