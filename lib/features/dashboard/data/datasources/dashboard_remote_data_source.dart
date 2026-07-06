import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../models/medical_record_response.dart';
import '../models/consultation_response.dart';

abstract class DashboardRemoteDataSource {
  Future<List<UserProfile>> getAllUsers();
  Future<List<Map<String, dynamic>>> getPatientsByDoctor(int doctorId);
  Future<MedicalRecordResponse?> getMedicalRecordByPatient(int patientId, {required int doctorId});
  Future<List<ConsultationResponse>> getConsultationsByMedicalRecord(int medicalRecordId);
  Future<List<ConsultationResponse>> getConsultationsFromPatientEndpoint(int patientId, {required int doctorId});
  Future<Map<String, dynamic>> getPatientDashboard(int patientId);
  Future<MedicalRecordResponse> createMedicalRecord(Map<String, dynamic> recordData);
  Future<RiskPrediction> evaluateRisk(int medicalRecordId);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final response = await _apiClient.get('/users/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => UserProfile.fromJson(item)).toList();
    }
    throw Exception('Error al obtener usuarios (Status: ${response.statusCode})');
  }

  @override
  Future<List<Map<String, dynamic>>> getPatientsByDoctor(int doctorId) async {
    final response = await _apiClient.get('/doctors/$doctorId/patients');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Error al obtener pacientes del doctor (Status: ${response.statusCode})');
  }

  @override
  Future<MedicalRecordResponse?> getMedicalRecordByPatient(int patientId, {required int doctorId}) async {
    try {
      final response = await _apiClient.get('/medical-records/patient/$patientId?doctor_id=$doctorId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The endpoint returns { medical_record: {...} | null, consultations: [], ... }
        if (data['medical_record'] == null) {
          return null; // Patient has no medical record yet
        }
        // Inject consultations and risk_prediction into the record for downstream use
        final merged = Map<String, dynamic>.from(data);
        return MedicalRecordResponse.fromJson(merged);
      }
      // 404 or other error: no record
      return null;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException')) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<ConsultationResponse>> getConsultationsFromPatientEndpoint(int patientId, {required int doctorId}) async {
    try {
      final response = await _apiClient.get('/medical-records/patient/$patientId?doctor_id=$doctorId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final consultationsList = data['consultations'];
        if (consultationsList is List) {
          return consultationsList.map((item) => ConsultationResponse.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ConsultationResponse>> getConsultationsByMedicalRecord(int medicalRecordId) async {
    final response = await _apiClient.get('/consultations/medical-record/$medicalRecordId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ConsultationResponse.fromJson(item)).toList();
    }
    throw Exception('Error al obtener consultas (Status: ${response.statusCode})');
  }

  @override
  Future<Map<String, dynamic>> getPatientDashboard(int patientId) async {
    final response = await _apiClient.get('/patients/$patientId/dashboard');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener dashboard (Status: ${response.statusCode})');
  }

  @override
  Future<MedicalRecordResponse> createMedicalRecord(Map<String, dynamic> recordData) async {
    final response = await _apiClient.post('/medical-records/', recordData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return MedicalRecordResponse.fromJson(data);
    }

    String errorMsg = 'Error al crear expediente (Status: ${response.statusCode})';
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
      } else {
        errorMsg = response.body;
      }
    } catch (_) {
      errorMsg = response.body;
    }
    throw Exception(errorMsg);
  }

  @override
  Future<RiskPrediction> evaluateRisk(int medicalRecordId) async {
    final response = await _apiClient.post('/medical-records/$medicalRecordId/risk-evaluation', {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return RiskPrediction.fromJson(data as Map<String, dynamic>);
    }

    String errorMsg = 'Error al evaluar riesgo (Status: ${response.statusCode})';
    try {
      final errorJson = jsonDecode(response.body);
      final detail = errorJson['detail'];
      if (detail is String) {
        errorMsg = detail;
      } else if (errorJson['message'] != null) {
        errorMsg = errorJson['message'];
      } else {
        errorMsg = response.body;
      }
    } catch (_) {
      errorMsg = response.body;
    }
    throw Exception(errorMsg);
  }
}
