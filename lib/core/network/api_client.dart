import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await _client.get(url, headers: _headers);
    return response;
  }

  Future<http.Response> getById(String endpoint) async {
    return get(endpoint);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await _client.put(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await _client.delete(url, headers: _headers);
    return response;
  }

  void dispose() {
    _client.close();
  }
}