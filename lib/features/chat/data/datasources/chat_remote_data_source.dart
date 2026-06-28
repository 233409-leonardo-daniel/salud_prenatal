import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/api_config.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_dto.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationDto>> getConversations(int currentUserId);
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
  
  bool _isOfflineMode = false;
  int? _currentUserId;
  bool _isConnected = false;
  
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  ChatRemoteDataSourceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<ConversationDto>> getConversations(int currentUserId) async {
    try {
      final response = await _apiClient.get('/chat/conversations?user_id=$currentUserId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ConversationDto.fromJson(item)).toList();
      }
      throw Exception('Error al obtener conversaciones (Status: ${response.statusCode})');
    } catch (e) {
      // Mock data if backend not available
      return [
        ConversationDto(
          id: 1,
          participant1Id: currentUserId,
          participant2Id: 2,
          participant1Name: 'Recepcionista',
          participant2Name: 'María López',
          unreadCount: 2,
          updatedAt: DateTime.now().toIso8601String(),
        ),
        ConversationDto(
          id: 2,
          participant1Id: currentUserId,
          participant2Id: 1,
          participant1Name: 'Recepcionista',
          participant2Name: 'Dr. Pedro Gómez',
          unreadCount: 0,
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        ),
      ];
    }
  }

  @override
  Future<List<ChatMessageModel>> getChatHistory(int otherUserId, int currentUserId) async {
    try {
      final response = await _apiClient.get('/chat/history/$otherUserId?current_user_id=$currentUserId');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ChatMessageModel.fromJson(item)).toList();
      }
      throw Exception('Error al cargar historial (Status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') || 
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        return [
          ChatMessageModel(
            messageId: 101,
            senderId: otherUserId, 
            receiverId: currentUserId, 
            content: "Hola, necesito información sobre mi cita.",
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            isRead: true,
          ),
          ChatMessageModel(
            messageId: 102,
            senderId: currentUserId, 
            receiverId: otherUserId, 
            content: "Claro, ¿me indicas tu nombre completo por favor?",
            createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
            isRead: true,
          ),
        ];
      }
      rethrow;
    }
  }

  @override
  Future<void> connect(int currentUserId) async {
    if (_isConnected) return;
    
    _currentUserId = currentUserId;
    _isDisposed = false;
    
    final httpUrl = ApiConfig.baseUrl;
    final wsScheme = httpUrl.startsWith('https') ? 'wss' : 'ws';
    final hostAndPath = httpUrl.replaceFirst(RegExp(r'^https?://'), '');
    final socketUrl = '$wsScheme://$hostAndPath/chat/ws/$currentUserId';

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
      _isOfflineMode = false;
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
      debugPrint('Fallo de conexión WebSocket: $e. Entrando en modo offline simulado.');
      _isOfflineMode = true;
      _isConnected = true; // Simulado
      _connectionController.add(true);
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
    if (!_isConnected) {
      debugPrint('Error: No se pueden enviar mensajes sin conexión.');
      return;
    }

    final messageJson = {
      'receiver_id': receiverId,
      'content': content,
    };

    if (_isOfflineMode) {
      final echoMessage = ChatMessageModel(
        messageId: DateTime.now().millisecondsSinceEpoch,
        senderId: _currentUserId ?? 99,
        receiverId: receiverId,
        content: content,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      _messageController.add(echoMessage);
      _triggerOfflineReply(receiverId);
    } else {
      if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
        _webSocket!.add(jsonEncode(messageJson));
      } else {
        debugPrint('Error: El WebSocket no está listo. Intentando reconectar...');
        _handleDisconnect();
      }
    }
  }

  void _triggerOfflineReply(int receiverId) {
    Timer(const Duration(milliseconds: 1500), () {
      if (_isOfflineMode && _isConnected && !_isDisposed) {
        final mockReply = ChatMessageModel(
          messageId: DateTime.now().millisecondsSinceEpoch + 1,
          senderId: receiverId,
          receiverId: _currentUserId ?? 99,
          content: "Este es un mensaje de prueba offline",
          createdAt: DateTime.now(),
          isRead: false,
        );
        _messageController.add(mockReply);
      }
    });
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
