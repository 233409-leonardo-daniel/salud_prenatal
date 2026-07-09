import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_config.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatMessageModel>> getChatHistory(int otherUserId, int currentUserId);
  Stream<ChatMessageModel> get messageStream;
  Stream<bool> get connectionStatusStream;
  Future<void> connect(int currentUserId);
  void sendMessage(int receiverId, String content);
  void disconnect();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;
  
  WebSocket? _webSocket;
  final StreamController<ChatMessageModel> _messageController = StreamController<ChatMessageModel>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  int? _currentUserId;
  bool _isConnected = false;
  
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  ChatRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<ChatMessageModel>> getChatHistory(int otherUserId, int currentUserId) async {
    final response = await _apiClient.get('/chat/history/$otherUserId?current_user_id=$currentUserId');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ChatMessageModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener el historial del chat (Status: ${response.statusCode})');
  }

  @override
  Future<void> connect(int currentUserId) async {
    if (_isConnected && _webSocket != null && _webSocket!.readyState == WebSocket.open) return;
    
    _currentUserId = currentUserId;
    _isDisposed = false;
    
    final httpUrl = ApiConfig.baseUrl;
    final uri = Uri.parse(httpUrl);
    final host = uri.host;
    final port = uri.hasPort ? uri.port : 8000;
    final path = uri.path;
    final socketUrl = 'ws://$host:$port$path/chat/ws/$currentUserId';

    debugPrint('Intentando conectar WebSocket a: $socketUrl');
    
    try {
      Map<String, dynamic>? wsHeaders;
      final token = ApiClient().authToken;
      if (token != null) {
        wsHeaders = {
          'Authorization': 'Bearer $token',
        };
      }
      _webSocket = await WebSocket.connect(socketUrl, headers: wsHeaders).timeout(const Duration(seconds: 5));
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('WebSocket conectado exitosamente.');

      _webSocket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            final message = ChatMessageModel.fromJson(decoded);
            _messageController.add(message);
          } catch (e) {
            debugPrint('Error decodificando mensaje de WebSocket: $e');
          }
        },
        onError: (err) {
          debugPrint('Error en WebSocket stream: $err');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebSocket cerrado por el servidor.');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Fallo de conexión WebSocket: $e. Reintentando en 5 segundos...');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    
    if (_isDisposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && _currentUserId != null) {
        debugPrint('Intentando reconectar WebSocket...');
        connect(_currentUserId!);
      }
    });
  }

  @override
  void sendMessage(int receiverId, String content) {
    try {
      if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
        final messageJson = {
          'receiver_id': receiverId,
          'content': content,
        };
        _webSocket!.add(jsonEncode(messageJson));
        debugPrint('Mensaje enviado vía WebSocket: $messageJson');
      } else {
        debugPrint('Error: El WebSocket no está listo. Intentando reconectar...');
        _handleDisconnect();
      }
    } catch (e) {
      debugPrint('Error enviando mensaje por WebSocket: $e');
      _handleDisconnect();
    }
  }

  @override
  void disconnect() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _webSocket?.close();
    _webSocket = null;
    _isConnected = false;
    _connectionController.add(false);
  }
}
