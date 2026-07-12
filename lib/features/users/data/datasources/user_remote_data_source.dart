import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_dto.dart';

abstract class UserRemoteDataSource {
  Future<List<UserDto>> getDoctors();
  Future<List<UserDto>> getPatients({int? doctorId});
  Future<UserDto> getUserById(int id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient _apiClient;
  static final Map<int, int> _userToDoctorMap = {};

  UserRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<UserDto>> getDoctors() async {
    final response = await _apiClient.get('/users');
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
  Future<UserDto> getUserById(int id) async {
    final response = await _apiClient.get('/users/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var user = UserDto.fromJson(data);

      final isDoc = user.role.toLowerCase() == 'doctor' || user.role.toLowerCase() == 'doctor(a)';
      if (isDoc) {
        int? docId = _userToDoctorMap[id] ?? data['doctor_id'] ?? data['doctorId'];
        
        if (docId == null) {
          // Scan doctors sequentially to map user_id -> doctor_id (up to 50, stopping on 5 consecutive failures)
          int consecutiveFailures = 0;
          for (int testId = 1; testId <= 50; testId++) {
            try {
              final docResponse = await _apiClient.get('/doctors/$testId');
              if (docResponse.statusCode == 200) {
                consecutiveFailures = 0;
                final docData = jsonDecode(docResponse.body);
                final int docUserId = docData['user_id'] ?? 0;
                final int foundDocId = docData['doctor_id'] ?? testId;
                if (docUserId > 0) {
                  _userToDoctorMap[docUserId] = foundDocId;
                  if (docUserId == id) {
                    docId = foundDocId;
                  }
                }
              } else {
                consecutiveFailures++;
              }
            } catch (_) {
              consecutiveFailures++;
            }
            if (consecutiveFailures >= 5) break;
            if (docId != null) break;
          }
        }

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
