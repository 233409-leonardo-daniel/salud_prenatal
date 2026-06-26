import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository);

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;

  int? _currentUserId;
  int? _otherUserId;

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;

  Future<void> initChat(int currentUserId, int otherUserId) async {
    // If transitioning to a new user chat, close the previous one first
    if (_currentUserId != null || _otherUserId != null) {
      await closeChat();
    }

    _currentUserId = currentUserId;
    _otherUserId = otherUserId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Cargar historial de mensajes previo por HTTP
      final history = await _repository.getChatHistory(otherUserId, currentUserId);
      _messages = List.from(history);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _isLoading = false;
      notifyListeners();

      // 2. Conectar al WebSocket
      await _repository.connect(currentUserId);
      _isConnected = true; // Assume connected initially/Offline Mode fallback
      notifyListeners();

      // 3. Suscribirse a mensajes entrantes en tiempo real
      _messageSubscription = _repository.messageStream.listen((message) {
        // Verificar si el mensaje pertenece a la conversación actual
        final isBelonging = (message.senderId == currentUserId && message.receiverId == otherUserId) ||
                            (message.senderId == otherUserId && message.receiverId == currentUserId);
        
        if (isBelonging) {
          // Evitar duplicaciones (por ejemplo, el eco de confirmación del propio socket)
          final isDuplicated = _messages.any((msg) =>
              msg.messageId == message.messageId ||
              (msg.senderId == message.senderId &&
               msg.content == message.content &&
               msg.createdAt.difference(message.createdAt).inSeconds.abs() < 3));

          if (!isDuplicated) {
            _messages.add(message);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
          }
        }
      });

      // 4. Suscribirse a cambios en el estado de la conexión
      _connectionSubscription = _repository.connectionStatusStream.listen((connected) {
        _isConnected = connected;
        notifyListeners();
      });

    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void sendMessage(String content) {
    if (_currentUserId == null || _otherUserId == null) {
      debugPrint('Error: Chat no inicializado.');
      return;
    }
    
    if (content.trim().isEmpty) return;

    // Enviar el mensaje a través del repositorio
    _repository.sendMessage(_otherUserId!, content.trim());
  }

  Future<void> closeChat() async {
    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _messageSubscription = null;
    _connectionSubscription = null;
    _repository.disconnect();
    
    _messages = [];
    _currentUserId = null;
    _otherUserId = null;
    _isConnected = false;
    _isLoading = false;
    _errorMessage = null;
  }

  @override
  void dispose() {
    closeChat();
    super.dispose();
  }
}
