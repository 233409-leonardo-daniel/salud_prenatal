import 'dart:convert';
import '../../../../core/network/api_client.dart';

abstract class InvitationRemoteDataSource {
  Future<Map<String, dynamic>> generateInvitationCode(int doctorId);
  Future<Map<String, dynamic>> redeemCode(int patientId, String code);
}

class InvitationRemoteDataSourceImpl implements InvitationRemoteDataSource {
  final ApiClient _apiClient;

  InvitationRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Map<String, dynamic>> generateInvitationCode(int doctorId) async {
    final response = await _apiClient.post('/doctors/$doctorId/invitation-code', {});

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Error al generar código de invitación (Status: ${response.statusCode})');
  }

  @override
  Future<Map<String, dynamic>> redeemCode(int patientId, String code) async {
    final response = await _apiClient.post('/patients/$patientId/redeem-code', {'code': code});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    final body = jsonDecode(response.body);
    final detail = body['detail'] ?? 'Error al canjear código';
    throw Exception(detail);
  }
}
