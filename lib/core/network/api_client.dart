import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Provee el token de autenticación vigente al construir cada request.
/// Modelo PULL: [ApiClient] jala el token vía este closure (lo cablea
/// [CoreModule] como `() => sessionManager.token`), en lugar de guardarlo.
typedef TokenProvider = String? Function();

class ApiClient {
  final http.Client _client;
  final TokenProvider? _tokenProvider;
  static final StreamController<void> _paymentRequiredController = StreamController<void>.broadcast();

  /// Se emite cada vez que el backend responde 402 (suscripción de doctor
  /// inactiva) a cualquier request, sin importar qué instancia de ApiClient
  /// lo haya hecho. Es un bus de eventos de infraestructura (no estado de
  /// sesión), por eso se mantiene estático.
  static Stream<void> get onPaymentRequired => _paymentRequiredController.stream;

  ApiClient({http.Client? client, TokenProvider? tokenProvider})
      : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  void _notifyIfPaymentRequired(http.Response response) {
    if (response.statusCode == 402) {
      _paymentRequiredController.add(null);
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _tokenProvider?.call();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUrl(String endpoint) {
    String base = ApiConfig.baseUrl;
    if (base.endsWith('/') && endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    } else if (!base.endsWith('/') && !endpoint.startsWith('/')) {
      endpoint = '/$endpoint';
    }
    return Uri.parse('$base$endpoint');
  }

  Future<http.Response> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    final response = await _client.get(url, headers: _headers);
    _notifyIfPaymentRequired(response);
    return response;
  }

  Future<http.Response> getById(String endpoint) async {
    return get(endpoint);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUrl(endpoint);
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    _notifyIfPaymentRequired(response);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUrl(endpoint);
    final response = await _client.put(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    _notifyIfPaymentRequired(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final response = await _client.delete(url, headers: _headers);
    _notifyIfPaymentRequired(response);
    return response;
  }

  void dispose() {
    _client.close();
  }
}