import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../pages/chat_state.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository;

  ChatProvider(this._repository);

  /// Si tras enviar un mensaje no llega el eco de confirmación del servidor en
  /// este lapso, se marca como fallido para que el usuario pueda reintentar.
  static const Duration _confirmTimeout = Duration(seconds: 12);

  List<ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.initial;
  bool _isConnected = false;
  String? _errorMessage;

  int? _currentUserId;
  int? _otherUserId;

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  /// Timers de confirmación pendientes, indexados por `clientId` del mensaje
  /// optimista. Se cancelan al confirmarse el mensaje o al cerrar el chat.
  final Map<String, Timer> _pendingConfirmations = {};

  List<ChatMessage> get messages => _messages;
  ChatStatus get status => _status;
  bool get isLoading => _status == ChatStatus.loading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;

  Future<void> initChat(int currentUserId, int otherUserId) async {
    // If transitioning to a new user chat, close the previous one first
    if (_currentUserId != null || _otherUserId != null) {
      await closeChat();
    }

    _currentUserId = currentUserId;
    _otherUserId = otherUserId;
    _status = ChatStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Cargar historial de mensajes previo por HTTP
      final history = await _repository.getChatHistory(otherUserId, currentUserId);
      _messages = List.from(history);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _status = ChatStatus.success;
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

        if (!isBelonging) return;

        // 3a. Si es el eco de confirmación de un mensaje propio que enviamos de
        // forma optimista, lo reconciliamos: reemplazamos el placeholder
        // "enviando" por el mensaje real del servidor (con su message_id) y lo
        // marcamos como enviado, en vez de tratarlo como duplicado y descartarlo.
        if (message.senderId == currentUserId) {
          final pendingIdx = _messages.indexWhere((m) =>
              m.clientId != null &&
              m.status != MessageStatus.sent &&
              m.content == message.content);
          if (pendingIdx != -1) {
            final clientId = _messages[pendingIdx].clientId;
            _messages[pendingIdx] = message.copyWith(status: MessageStatus.sent);
            _clearConfirmation(clientId);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
            return;
          }
        }

        // 3b. Deduplicación normal (mensajes entrantes u otros ecos): se ignoran
        // los mensajes optimistas propios (clientId != null), que ya se
        // reconcilian arriba.
        final isDuplicated = _messages.any((msg) =>
            (msg.messageId != 0 && msg.messageId == message.messageId) ||
            (msg.clientId == null &&
             msg.senderId == message.senderId &&
             msg.content == message.content &&
             msg.createdAt.difference(message.createdAt).inSeconds.abs() < 3));

        if (!isDuplicated) {
          _messages.add(message);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          notifyListeners();

          // Si el mensaje es recibido del otro usuario (estamos leyéndolo en vivo),
          // hacemos un fetch de confirmación silencioso al endpoint de history.
          // Esto marca los mensajes como leídos en la base de datos para que el
          // unread_count del inbox quede en 0.
          if (message.senderId == otherUserId) {
            _repository.getChatHistory(otherUserId, currentUserId).catchError((e) {
              debugPrint('Error al marcar mensajes como leídos en segundo plano: $e');
              return <ChatMessage>[];
            });
          }
        }
      });

      // 4. Suscribirse a cambios en el estado de la conexión
      _connectionSubscription = _repository.connectionStatusStream.listen((connected) {
        _isConnected = connected;
        notifyListeners();
      });

    } catch (e) {
      _status = ChatStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Envío optimista: el mensaje aparece de inmediato en la lista con estado
  /// "enviando" (sin esperar la confirmación del servidor). Si el socket no
  /// pudo mandarlo, se marca como fallido al instante; si sí, un timer de
  /// respaldo lo marca como fallido cuando no llega el eco a tiempo. El eco de
  /// confirmación (ver listener de `messageStream`) lo pasa a "enviado".
  void sendMessage(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    if (_currentUserId == null || _otherUserId == null) {
      debugPrint('Error: Chat no inicializado.');
      return;
    }

    final clientId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      messageId: 0,
      senderId: _currentUserId!,
      receiverId: _otherUserId!,
      content: trimmed,
      createdAt: DateTime.now(),
      isRead: false,
      status: MessageStatus.sending,
      clientId: clientId,
    );

    _messages.add(optimistic);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    _dispatch(clientId, trimmed);
  }

  /// Reintenta un mensaje que quedó en estado fallido, volviéndolo a "enviando".
  void retryMessage(ChatMessage message) {
    final clientId = message.clientId;
    if (clientId == null || message.status != MessageStatus.failed) return;

    if (_currentUserId == null || _otherUserId == null) return;

    _updateByClientId(clientId, (m) => m.copyWith(status: MessageStatus.sending));
    _dispatch(clientId, message.content);
  }

  /// Manda el mensaje por el repositorio y arma el manejo de confirmación:
  /// fallo inmediato si el socket no estaba abierto, o timer de respaldo si sí.
  void _dispatch(String clientId, String content) {
    final ok = _repository.sendMessage(_otherUserId!, content);
    if (!ok) {
      _updateByClientId(clientId, (m) => m.copyWith(status: MessageStatus.failed));
      return;
    }

    _pendingConfirmations[clientId]?.cancel();
    _pendingConfirmations[clientId] = Timer(_confirmTimeout, () {
      _pendingConfirmations.remove(clientId);
      _updateByClientId(clientId, (m) =>
          m.status == MessageStatus.sending ? m.copyWith(status: MessageStatus.failed) : m);
    });
  }

  void _clearConfirmation(String? clientId) {
    if (clientId == null) return;
    _pendingConfirmations.remove(clientId)?.cancel();
  }

  /// Aplica [update] al mensaje optimista con el [clientId] dado y notifica.
  void _updateByClientId(String clientId, ChatMessage Function(ChatMessage) update) {
    final idx = _messages.indexWhere((m) => m.clientId == clientId);
    if (idx == -1) return;
    final updated = update(_messages[idx]);
    if (identical(updated, _messages[idx])) return;
    _messages[idx] = updated;
    notifyListeners();
  }

  Future<void> closeChat() async {
    for (final timer in _pendingConfirmations.values) {
      timer.cancel();
    }
    _pendingConfirmations.clear();

    await _messageSubscription?.cancel();
    await _connectionSubscription?.cancel();
    _messageSubscription = null;
    _connectionSubscription = null;
    _repository.disconnect();

    _messages = [];
    _currentUserId = null;
    _otherUserId = null;
    _isConnected = false;
    _status = ChatStatus.initial;
    _errorMessage = null;
  }

  @override
  void dispose() {
    closeChat();
    super.dispose();
  }
}
