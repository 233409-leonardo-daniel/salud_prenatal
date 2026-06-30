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
    final url = doctorId != null ? '/doctors/$doctorId/patients' : '/users';
    final response = await _apiClient.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final list = data.map((e) => UserDto.fromJson(e)).toList();
      return list.where((u) => u.role.toLowerCase() == 'paciente' || u.role.toLowerCase() == 'patient').toList();
    }
    throw Exception('Error al obtener pacientes');
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
