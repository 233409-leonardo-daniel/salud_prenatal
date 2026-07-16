import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/subscription_status_model.dart';

abstract class SubscriptionsRemoteDataSource {
  Future<SubscriptionStatusModel> getStatus();

  /// [paymentMode]: `"recurring"` (tarjeta, renovación automática) o
  /// `"one_time"` (habilita OXXO/SPEI, pago de un solo mes).
  Future<String> createCheckoutSession(String planType, String paymentMode);

  /// Reobtiene un JWT fresco tras confirmarse el pago. El gating lee
  /// `subscription_status` desde el token, así que hay que reemplazarlo.
  /// Devuelve el nuevo `access_token`.
  Future<String> refreshToken();
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
  Future<String> createCheckoutSession(String planType, String paymentMode) async {
    final response = await _apiClient.post(
      '/subscriptions/checkout-session',
      {'plan_type': planType, 'payment_mode': paymentMode},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['checkout_url'] ?? '';
    }
    throw Exception(_extractDetail(response.body, response.statusCode, 'Error al iniciar el proceso de pago'));
  }

  @override
  Future<String> refreshToken() async {
    final response = await _apiClient.post('/users/refresh', {});
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['access_token'] ?? data['accessToken'] ?? '';
    }
    throw Exception(_extractDetail(response.body, response.statusCode, 'Error al actualizar la sesión'));
  }
}
