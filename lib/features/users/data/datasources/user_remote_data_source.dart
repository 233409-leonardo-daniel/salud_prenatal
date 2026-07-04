import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/user_dto.dart';

abstract class UserRemoteDataSource {
  Future<List<UserDto>> getDoctors();
  Future<List<UserDto>> getPatients({int? doctorId});
  Future<UserDto> getUserById(int id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient _apiClient;

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
      return UserDto.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener usuario');
  }
}
