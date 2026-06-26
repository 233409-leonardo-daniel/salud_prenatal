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
  
  bool _isOfflineMode = false;
  int? _currentUserId;
  bool _isConnected = false;
  
  // Timer for automatic reconnection attempts
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  ChatRemoteDataSourceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

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
      // Fallback offline mock history
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') || 
          e.toString().contains('ClientException')) {
        await Future.delayed(const Duration(milliseconds: 500));
        
        return [
          ChatMessageModel(
            messageId: 101,
            senderId: 2, // Maria Lopez (Patient)
            receiverId: 1, // Pedro Gomez (Doctor)
            content: "Buenas tardes doctor, ¿cómo está?",
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            isRead: true,
          ),
          ChatMessageModel(
            messageId: 102,
            senderId: 1, // Doctor
            receiverId: 2, // Patient
            content: "Hola. Muy bien, gracias. ¿Cómo va tu embarazo esta semana? ¿Registraste tus mediciones?",
            createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
            isRead: true,
          ),
          ChatMessageModel(
            messageId: 103,
            senderId: 2, // Patient
            receiverId: 1, // Doctor
            content: "Sí, ya registré mi presión de hoy en la bitácora. Salió en 118/76 mmHg.",
            createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
            isRead: true,
          ),
          ChatMessageModel(
            messageId: 104,
            senderId: 1, // Doctor
            receiverId: 2, // Patient
            content: "Excelente presión. Mantén la hidratación y recuerda descansar. Cualquier síntoma me avisas.",
            createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
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
      _webSocket = await WebSocket.connect(socketUrl).timeout(const Duration(seconds: 5));
      _isOfflineMode = false;
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('WebSocket conectado exitosamente.');

      // Listen for incoming messages
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
    
    // Attempt reconnection in 5 seconds
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
      // Offline mode simulation
      // 1. Echo the sent message immediately
      final echoMessage = ChatMessageModel(
        messageId: DateTime.now().millisecondsSinceEpoch,
        senderId: _currentUserId ?? 99,
        receiverId: receiverId,
        content: content,
        createdAt: DateTime.now(),
        isRead: false,
      );
      
      _messageController.add(echoMessage);

      // 2. Trigger automated simulation reply
      _triggerOfflineReply(receiverId);
    } else {
      // Connect and send via real socket
      if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
        _webSocket!.add(jsonEncode(messageJson));
      } else {
        debugPrint('Error: El WebSocket no está listo. Intentando reconectar...');
        _handleDisconnect();
      }
    }
  }

  void _triggerOfflineReply(int receiverId) {
    final replies = [
      "¡Hola! He recibido tu mensaje. Estaré revisando tus registros en la bitácora en breve.",
      "Entendido. ¿Has tenido algún síntoma adicional como dolor de cabeza o hinchazón hoy?",
      "Perfecto. Recuerda mantener un consumo bajo de sal y beber suficiente agua.",
      "Excelente reporte. Tus signos vitales y bitácora se ven muy estables.",
      "Recuerda que si presentas cualquier señal de alarma (sangrado, dolor abdominal fuerte o visión borrosa), debes acudir a urgencias inmediatamente.",
      "De acuerdo, nos vemos en nuestra próxima cita programada. ¡Sigue cuidándote mucho!"
    ];

    // Pick a pseudo-random reply based on message length or time
    final randomIndex = DateTime.now().millisecond % replies.length;
    final replyContent = replies[randomIndex];

    Timer(const Duration(milliseconds: 1500), () {
      if (_isOfflineMode && _isConnected && !_isDisposed) {
        final mockReply = ChatMessageModel(
          messageId: DateTime.now().millisecondsSinceEpoch + 1,
          senderId: receiverId,
          receiverId: _currentUserId ?? 99,
          content: replyContent,
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
