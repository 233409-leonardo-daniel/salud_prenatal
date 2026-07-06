import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/register_request.dart';

abstract class RegisterRemoteDataSource {
  Future<Map<String, dynamic>> registerPatient(PatientRegisterRequest request);
  Future<String> registerDoctor(DoctorRegisterRequest request);
  Future<String> registerReceptionist(ReceptionistRegisterRequest request, int doctorId);
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final ApiClient _apiClient;

  RegisterRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> registerPatient(PatientRegisterRequest request) async {
    // El expediente clínico ya no se captura en el registro: el paciente solo
    // manda su identidad + fecha de nacimiento (+ doctor opcional).
    final response = await _apiClient.post(
      '/patients/register',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : <String, dynamic>{'token': data.toString()};
    }

    // Procesar y formatear errores detallados de validación (FastAPI/Pydantic style)
    String errorMsg = 'Error al registrar (Status: ${response.statusCode})';
    try {
      final errorJson = jsonDecode(response.body);
      final detail = errorJson['detail'];
      if (detail is String) {
        errorMsg = detail;
      } else if (detail is List && detail.isNotEmpty) {
        // Combina la localización y el mensaje de error de FastAPI
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
  Future<String> registerDoctor(DoctorRegisterRequest request) async {
    final userMap = {
      'name': request.name,
      'last_name': request.lastName,
      'email': request.email,
      'phone': request.phone,
      'password': request.password,
    };

    final payload = {
      'professional_license': request.professionalLicense,
      'specialty': request.specialty,
      'office': request.office,
      'user': userMap,
      ...userMap,
    };

    final response = await _apiClient.post(
      '/doctors/register',
      payload,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['access_token'] ?? data['token'] ?? 'success';
    }

    String errorMsg = 'Error al registrar (Status: ${response.statusCode})';
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
  Future<String> registerReceptionist(ReceptionistRegisterRequest request, int doctorId) async {
    final response = await _apiClient.post(
      '/doctors/$doctorId/receptionists',
      request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'receptionist_registered';
    }

    String errorMsg = 'Error al registrar recepcionista (Status: ${response.statusCode})';
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
}
