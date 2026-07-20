import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_dto.dart';

abstract class UserRemoteDataSource {
  Future<List<UserDto>> getDoctors();
  Future<List<UserDto>> getPatients({int? doctorId});
  Future<UserDto> getUserById(int id, {int? doctorId});
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient _apiClient;
  static final Map<int, int> _userToDoctorMap = {};

  UserRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<UserDto>> getDoctors() async {
    // Ruta de colección con '/' final: evita el redirect 307 del gateway
    // (el resto del código ya usa '/users/').
    final response = await _apiClient.get('/users/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final list = data.map((e) => UserDto.fromJson(e)).toList();
      return list.where((u) => u.role.toLowerCase() == 'doctor').toList();
    }
    throw Exception('Error al obtener doctores');
  }

  @override
  Future<List<UserDto>> getPatients({int? doctorId}) async {
    // 1. Obtener todos los usuarios para tener detalles de perfil (nombre, email, etc.)
    final usersResponse = await _apiClient.get('/users/');
    if (usersResponse.statusCode != 200) {
      throw Exception('Error al obtener usuarios (Status: ${usersResponse.statusCode})');
    }
    final List<dynamic> usersData = jsonDecode(usersResponse.body);
    final allUsers = usersData.map((e) => UserDto.fromJson(e)).toList();
    final allPatients = allUsers.where((u) => u.role.toLowerCase() == 'paciente' || u.role.toLowerCase() == 'patient').toList();

    // 2. Si se especifica un doctorId, filtrar solo los pacientes de ese doctor
    if (doctorId != null) {
      final patientsResponse = await _apiClient.get('/doctors/$doctorId/patients');
      if (patientsResponse.statusCode == 200) {
        final List<dynamic> patientsData = jsonDecode(patientsResponse.body);
        final patientUserIds = patientsData.map((p) => p['user_id'] as int).toSet();
        return allPatients.where((u) => patientUserIds.contains(u.id)).toList();
      }
      throw Exception('Error al obtener pacientes del doctor (Status: ${patientsResponse.statusCode})');
    }
    return allPatients;
  }

  @override
  Future<UserDto> getUserById(int id, {int? doctorId}) async {
    final response = await _apiClient.get('/users/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var user = UserDto.fromJson(data);

      final isDoc = user.role.toLowerCase() == 'doctor' || user.role.toLowerCase() == 'doctor(a)';
      if (isDoc) {
        // `doctorId` conocido (sesión), caché en memoria, o el propio
        // /users/{id}. Ya NO se escanea /doctors/1..50 (era una ráfaga de
        // hasta 50 peticiones); si no se conoce, se omite el detalle.
        final int? docId = doctorId ?? _userToDoctorMap[id] ?? data['doctor_id'] ?? data['doctorId'];

        if (docId != null) {
          _userToDoctorMap[id] = docId;
          try {
            final docResponse = await _apiClient.get('/doctors/$docId');
            if (docResponse.statusCode == 200) {
              final docData = jsonDecode(docResponse.body);
              user = UserDto(
                id: user.id,
                email: docData['email'] ?? user.email,
                fullName: '${docData['name'] ?? ''} ${docData['last_name'] ?? ''}'.trim().isNotEmpty
                    ? '${docData['name']} ${docData['last_name']}'.trim()
                    : user.fullName,
                role: user.role,
                phoneNumber: docData['phone'] ?? user.phoneNumber,
                profilePicture: docData['image_url'] ?? user.profilePicture,
                doctorId: docId,
                specialty: docData['specialty'],
                professionalLicense: docData['professional_license'],
                office: docData['office'],
                // Se conserva el is_active de /users/{id}: el detalle del
                // doctor (/doctors/{id}) no trae ese campo.
                isActive: user.isActive,
              );
            }
          } catch (e) {
            debugPrint('Error al obtener detalles del doctor $docId en getUserById: $e');
          }
        }
      }
      return user;
    }
    throw Exception('Error al obtener usuario');
  }
}
