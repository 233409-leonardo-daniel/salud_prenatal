import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/appointment_dto.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentDto>> getAppointmentsByUserId(String userId, {bool isDoctor = false});
  Future<List<AppointmentDto>> getAppointments({int? doctorId, int? patientId, String? status, String? date});
  Future<AppointmentDto> getAppointmentById(int id);
  Future<void> createAppointment(AppointmentDto dto);
  Future<void> updateAppointment(AppointmentDto dto);
  Future<void> updateAppointmentStatus(int id, StatusUpdateDto statusDto);
  Future<void> deleteAppointment(int id);
  Future<Map<String, dynamic>> checkAvailability(int doctorId, String date);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final ApiClient _apiClient;

  AppointmentRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<AppointmentDto>> getAppointmentsByUserId(String userId, {bool isDoctor = false}) async {
    final endpoint = isDoctor
        ? '/appointments/doctor/$userId'
        : '/appointments/patient/$userId';
        
    final response = await _apiClient.get(endpoint);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AppointmentDto.fromJson(item)).toList();
    }
    
    throw Exception('Error al obtener citas (Status: ${response.statusCode})');
  }

  @override
  Future<List<AppointmentDto>> getAppointments({int? doctorId, int? patientId, String? status, String? date}) async {
    String endpoint;
    if (doctorId != null) {
      endpoint = '/appointments/doctor/$doctorId';
    } else if (patientId != null) {
      endpoint = '/appointments/patient/$patientId';
    } else {
      // Fallback/Mock behavior if both are null, returning empty since backend doesn't support list all.
      return [];
    }
    
    final response = await _apiClient.get(endpoint);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AppointmentDto.fromJson(item)).toList();
    }
    
    throw Exception('Error al listar las citas (Status: ${response.statusCode})');
  }

  @override
  Future<AppointmentDto> getAppointmentById(int id) async {
    final response = await _apiClient.getById('/appointments/$id');
    
    if (response.statusCode == 200) {
      return AppointmentDto.fromJson(jsonDecode(response.body));
    }
    
    throw Exception('Error al obtener detalle de cita (Status: ${response.statusCode})');
  }

  @override
  Future<void> createAppointment(AppointmentDto dto) async {
    final response = await _apiClient.post('/appointments/', dto.toJson());
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<void> updateAppointment(AppointmentDto dto) async {
    final response = await _apiClient.put('/appointments/${dto.id}', dto.toJson());
    
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<void> updateAppointmentStatus(int id, StatusUpdateDto statusDto) async {
    final response = await _apiClient.put('/appointments/$id', {'status': statusDto.status});
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al actualizar estado de la cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<void> deleteAppointment(int id) async {
    final response = await _apiClient.delete('/appointments/$id');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<Map<String, dynamic>> checkAvailability(int doctorId, String date) async {
    final response = await _apiClient.get('/appointments/availability?doctor_id=$doctorId&date=$date');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al verificar disponibilidad (Status: ${response.statusCode})');
  }
}
