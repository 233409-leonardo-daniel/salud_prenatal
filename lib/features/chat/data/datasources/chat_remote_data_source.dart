import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/certificate_pinning.dart';
import '../../../../core/config/api_config.dart';
import '../../../login/domain/entities/user_profile.dart';
import '../models/chat_message_model.dart';
import '../models/inbox_item_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<InboxItemModel>> getInbox();
  Future<List<UserProfile>> getContacts();
  Future<List<ChatMessageModel>> getChatHistory(int otherUserId, int currentUserId);
  Stream<ChatMessageModel> get messageStream;
  Stream<bool> get connectionStatusStream;
  Future<void> connect(int currentUserId);
  void sendMessage(int receiverId, String content);
  void disconnect();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _apiClient;
  final TokenProvider _tokenProvider;

  WebSocket? _webSocket;
  final StreamController<ChatMessageModel> _messageController = StreamController<ChatMessageModel>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  int? _currentUserId;
  bool _isConnected = false;
  
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  ChatRemoteDataSourceImpl({
    required ApiClient apiClient,
    required TokenProvider tokenProvider,
  })  : _apiClient = apiClient,
        _tokenProvider = tokenProvider;

  @override
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  @override
  Stream<bool> get connectionStatusStream => _connectionController.stream;

  @override
  Future<List<InboxItemModel>> getInbox() async {
    final response = await _apiClient.get('/chat/inbox');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => InboxItemModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener bandeja de chat (Status: ${response.statusCode})');
  }

  @override
  Future<List<UserProfile>> getContacts() async {
    final response = await _apiClient.get('/chat/contacts');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => UserProfile.fromJson(item)).toList();
    }
    throw Exception('Error al obtener contactos de chat (Status: ${response.statusCode})');
  }

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

    // El WS no soporta headers custom en el server: el token va como query
    // param (`?token=<JWT>`), no como Authorization header. Ver docu de /chat.
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final token = _tokenProvider();
    if (token == null) {
      // Sin token el gateway rechaza el handshake con 403; conectar de todos
      // modos solo produce un bucle de reintentos silencioso.
      debugPrint('Chat: no hay token de sesión, no se intenta conectar el WebSocket.');
      _handleDisconnect(canRetry: false);
      return;
    }

    final socketUri = Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: '${baseUri.path}/chat/ws',
      queryParameters: {'token': token},
    );

    debugPrint('Intentando conectar WebSocket a: ${socketUri.replace(queryParameters: {'token': '***'})}');

    try {
      // customClient aplica el mismo SSL/TLS pinning que el resto de la app:
      // si un proxy intercepta el handshake wss, la conexión falla.
      _webSocket = await WebSocket.connect(
        socketUri.toString(),
        customClient: createPinnedHttpClient(),
      ).timeout(const Duration(seconds: 5));
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
          final closeCode = _webSocket?.closeCode;
          debugPrint('WebSocket cerrado por el servidor (code: $closeCode).');
          // Code 1008 = token inválido/expirado: el server no lo va a aceptar
          // de nuevo sin re-autenticación, reintentar ciegamente no sirve.
          _handleDisconnect(canRetry: closeCode != 1008);
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Fallo de conexión WebSocket: $e. Reintentando en 5 segundos...');
      _handleDisconnect();
    }
  }

  void _handleDisconnect({bool canRetry = true}) {
    _isConnected = false;
    _connectionController.add(false);

    if (_isDisposed) return;

    if (!canRetry) {
      debugPrint('Token inválido/expirado: no se reintentará la conexión automáticamente.');
      return;
    }

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
