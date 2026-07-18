import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  /// Falla de pinning / verificación TLS: la lanzamos como un `Exception` con
  /// mensaje claro para que los providers lo muestren como error controlado en
  /// la UI (no un crash). Se dispara cuando el certificado del servidor no
  /// coincide con el pineado, p. ej. bajo un ataque Man-in-the-Middle.
  Never _throwInsecureConnection() {
    throw Exception(
      'Conexión no segura: no se pudo verificar la identidad del servidor. '
      'Posible interceptación de la red. Intenta desde una red de confianza.',
    );
  }

  /// Envuelve cada petición para capturar los fallos de handshake/TLS del
  /// cliente pineado y traducirlos a un error legible.
  Future<http.Response> _run(Future<http.Response> Function() action) async {
    try {
      final response = await action();
      _notifyIfPaymentRequired(response);
      return response;
    } on HandshakeException {
      _throwInsecureConnection();
    } on TlsException {
      _throwInsecureConnection();
    }
  }

  Future<http.Response> get(String endpoint) =>
      _run(() => _client.get(_buildUrl(endpoint), headers: _headers));

  Future<http.Response> getById(String endpoint) => get(endpoint);

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) =>
      _run(() => _client.post(_buildUrl(endpoint),
          headers: _headers, body: jsonEncode(body)));

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) =>
      _run(() => _client.put(_buildUrl(endpoint),
          headers: _headers, body: jsonEncode(body)));

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) =>
      _run(() => _client.patch(_buildUrl(endpoint),
          headers: _headers, body: jsonEncode(body)));

  Future<http.Response> delete(String endpoint) =>
      _run(() => _client.delete(_buildUrl(endpoint), headers: _headers));

  void dispose() {
    _client.close();
  }
}