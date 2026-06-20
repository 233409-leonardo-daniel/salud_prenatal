import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/appointment_model.dart';
import '../../domain/entities/appointment.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointmentsByUserId(String userId, {bool isDoctor = false});
  Future<void> createAppointment(Appointment appointment);
  Future<void> updateAppointment(Appointment appointment);
  Future<void> deleteAppointment(String id);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final ApiClient _apiClient;

  AppointmentRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<AppointmentModel>> getAppointmentsByUserId(String userId, {bool isDoctor = false}) async {
    final endpoint = isDoctor
        ? '/appointments/doctor/$userId'
        : '/appointments/patient/$userId';
        
    final response = await _apiClient.get(endpoint);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => AppointmentModel.fromJson(item)).toList();
    }
    
    throw Exception('Error al obtener citas (Status: ${response.statusCode})');
  }

  @override
  Future<void> createAppointment(Appointment appointment) async {
    final payload = {
      'patient_id': int.tryParse(appointment.patientName) ?? 1,
      'doctor_id': int.tryParse(appointment.doctorName) ?? 1,
      'appointment_date': appointment.dateTime.toIso8601String(),
      'reason': appointment.reason,
    };
    
    final response = await _apiClient.post('/appointments/', payload);
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<void> updateAppointment(Appointment appointment) async {
    final payload = {
      'status': appointment.status.toString().split('.').last == 'completed'
          ? 'completada'
          : appointment.status.toString().split('.').last == 'cancelled'
              ? 'cancelada'
              : 'pendiente',
      'reason': appointment.reason,
      'appointment_date': appointment.dateTime.toIso8601String(),
    };
    
    final response = await _apiClient.put('/appointments/${appointment.id}', payload);
    
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cita (Status: ${response.statusCode})');
    }
  }

  @override
  Future<void> deleteAppointment(String id) async {
    final response = await _apiClient.delete('/appointments/$id');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar cita (Status: ${response.statusCode})');
    }
  }
}
