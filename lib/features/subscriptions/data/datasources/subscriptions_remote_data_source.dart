import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/subscription_status_model.dart';

abstract class SubscriptionsRemoteDataSource {
  Future<SubscriptionStatusModel> getStatus();
  Future<String> createCheckoutSession(String planType);
}

class SubscriptionsRemoteDataSourceImpl implements SubscriptionsRemoteDataSource {
  final ApiClient _apiClient;

  SubscriptionsRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  String _extractDetail(String body, int statusCode, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // body no es JSON válido, se usa el mensaje por defecto
    }
    return '$fallback ($statusCode)';
  }

  @override
  Future<SubscriptionStatusModel> getStatus() async {
    final response = await _apiClient.get('/subscriptions/me');
    if (response.statusCode == 200) {
      return SubscriptionStatusModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractDetail(response.body, response.statusCode, 'Error al obtener el estado de la suscripción'));
  }

  @override
  Future<String> createCheckoutSession(String planType) async {
    final response = await _apiClient.post('/subscriptions/checkout-session', {'plan_type': planType});
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['checkout_url'] ?? '';
    }
    throw Exception(_extractDetail(response.body, response.statusCode, 'Error al iniciar el proceso de pago'));
  }
}
