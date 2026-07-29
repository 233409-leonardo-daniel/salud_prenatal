import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/patient_model.dart';
import '../../../profile/domain/entities/user_profile.dart';

abstract class PatientsRemoteDataSource {
  Future<List<PatientModel>> getPatientsByDoctor(String doctorId);
  Future<UserProfile> getPatientDetails(String userId);
}

class PatientsRemoteDataSourceImpl implements PatientsRemoteDataSource {
  final ApiClient _apiClient;

  PatientsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<PatientModel>> getPatientsByDoctor(String doctorId) async {
    final response = await _apiClient.get('/doctors/$doctorId/patients');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => PatientModel.fromJson(item)).toList();
    }
    
    throw Exception('Error al obtener pacientes (Status: ${response.statusCode})');
  }

  @override
  Future<UserProfile> getPatientDetails(String userId) async {
    final response = await _apiClient.get('/users/$userId');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    }
    
    throw Exception('Error al obtener detalles del usuario (Status: ${response.statusCode})');
  }
}
