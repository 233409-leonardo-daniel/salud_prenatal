import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/unlink_request_model.dart';

abstract class UnlinkRequestRemoteDataSource {
  // Lado paciente
  Future<UnlinkRequestModel> createRequest(int patientId, String? reason);
  Future<List<UnlinkRequestModel>> getPatientRequests(int patientId, {String? status});
  Future<UnlinkRequestModel> cancelRequest(int patientId, int requestId);

  // Lado doctor
  Future<List<UnlinkRequestModel>> getDoctorRequests(int doctorId, {String? status});
  Future<UnlinkRequestModel> resolveRequest(int doctorId, int requestId, String status);
}

class UnlinkRequestRemoteDataSourceImpl implements UnlinkRequestRemoteDataSource {
  final ApiClient _apiClient;

  UnlinkRequestRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  /// El backend devuelve el `detail` en 4xx (409 duplicado, 400 sin doctor,
  /// 404 no encontrada). Se propaga ese texto para mostrarlo tal cual.
  Never _throwFromBody(dynamic body, int statusCode, String fallback) {
    String detail = fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        detail = decoded['detail'].toString();
      }
    } catch (_) {}
    throw Exception('$detail (Status: $statusCode)');
  }

  @override
  Future<UnlinkRequestModel> createRequest(int patientId, String? reason) async {
    final response = await _apiClient.post(
      '/patients/$patientId/unlink-requests',
      {'reason': reason},
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return UnlinkRequestModel.fromJson(jsonDecode(response.body));
    }
    _throwFromBody(response.body, response.statusCode, 'Error al crear la solicitud');
  }

  @override
  Future<List<UnlinkRequestModel>> getPatientRequests(int patientId, {String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await _apiClient.get('/patients/$patientId/unlink-requests$query');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UnlinkRequestModel.fromJson(e)).toList();
    }
    _throwFromBody(response.body, response.statusCode, 'Error al obtener solicitudes');
  }

  @override
  Future<UnlinkRequestModel> cancelRequest(int patientId, int requestId) async {
    final response = await _apiClient.delete('/patients/$patientId/unlink-requests/$requestId');
    if (response.statusCode == 200) {
      return UnlinkRequestModel.fromJson(jsonDecode(response.body));
    }
    _throwFromBody(response.body, response.statusCode, 'Error al cancelar la solicitud');
  }

  @override
  Future<List<UnlinkRequestModel>> getDoctorRequests(int doctorId, {String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await _apiClient.get('/doctors/$doctorId/unlink-requests$query');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UnlinkRequestModel.fromJson(e)).toList();
    }
    _throwFromBody(response.body, response.statusCode, 'Error al obtener solicitudes');
  }

  @override
  Future<UnlinkRequestModel> resolveRequest(int doctorId, int requestId, String status) async {
    final response = await _apiClient.patch(
      '/doctors/$doctorId/unlink-requests/$requestId',
      {'status': status},
    );
    if (response.statusCode == 200) {
      return UnlinkRequestModel.fromJson(jsonDecode(response.body));
    }
    _throwFromBody(response.body, response.statusCode, 'Error al resolver la solicitud');
  }
}
