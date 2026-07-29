import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_conversations_usecase.dart';

enum ConversationsViewState { initial, loading, success, error }

class ConversationsProvider with ChangeNotifier {
  final GetConversationsUsecase _getConversationsUseCase;
  // Interfaz de dominio (no un datasource/módulo concreto) usada únicamente
  // para escuchar el stream de mensajes entrantes y refrescar la bandeja de
  // entrada en tiempo real. Las páginas ya no necesitan instanciar su propio
  // ChatModule para lograr esto: basta con este provider.
  final ChatRepository? _repository;

  ConversationsProvider(this._getConversationsUseCase, [this._repository]);

  ConversationsViewState _viewState = ConversationsViewState.initial;
  String? _error;
  List<Conversation> _conversations = [];
  int? _currentUserId;
  StreamSubscription<dynamic>? _incomingMessageSubscription;

  /// "Marca de agua" de lectura por contacto (`otherUserId` -> fecha del último
  /// mensaje que ya se leyó). El backend no siempre refleja de inmediato que la
  /// conversación quedó leída, así que al recargar el inbox volvía a aparecer el
  /// badge de no-leídos aunque el usuario ya había abierto el chat. Con esta
  /// marca, forzamos el contador a 0 mientras no llegue un mensaje MÁS NUEVO que
  /// el que ya se leyó; cuando llega uno nuevo, la marca se descarta y vuelve a
  /// mandar el contador real del servidor.
  final Map<int, DateTime> _readWatermarks = {};

  ConversationsViewState get viewState => _viewState;
  String? get error => _error;
  List<Conversation> get conversations => _conversations;

  /// Carga la bandeja de conversaciones real del usuario desde GET /chat/inbox.
  Future<void> loadConversations(int currentUserId) async {
    _currentUserId = currentUserId;
    _viewState = ConversationsViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _getConversationsUseCase.call(currentUserId);
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _conversations = _applyReadWatermarks(result);
      _viewState = ConversationsViewState.success;
    } catch (e) {
      _viewState = ConversationsViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// Se suscribe a mensajes entrantes en tiempo real para volver a cargar la
  /// bandeja de conversaciones automáticamente. Requiere haber llamado antes
  /// a [loadConversations] al menos una vez (para conocer el usuario actual).
  /// Marca localmente como leída la conversación con [otherUserId] (badge de
  /// no-leídos a 0) para feedback instantáneo al entrar al chat, sin esperar
  /// el refresh completo del inbox que dispara la página al volver.
  void markConversationAsRead(int otherUserId) {
    final idx = _conversations.indexWhere((c) => c.participant2Id == otherUserId);
    if (idx == -1) return;

    final old = _conversations[idx];
    // Registramos hasta qué mensaje leyó el usuario, para que un refresh del
    // inbox (que puede seguir trayendo unread_count > 0 del servidor) no vuelva
    // a encender el badge de esta conversación.
    _readWatermarks[otherUserId] =
        old.lastMessage?.createdAt ?? DateTime.now();

    if (old.unreadCount == 0) {
      notifyListeners();
      return;
    }

    _conversations[idx] = Conversation(
      conversationId: old.conversationId,
      participant1Id: old.participant1Id,
      participant2Id: old.participant2Id,
      participant1Name: old.participant1Name,
      participant2Name: old.participant2Name,
      lastMessage: old.lastMessage,
      unreadCount: 0,
      updatedAt: old.updatedAt,
      otherUserRole: old.otherUserRole,
    );
    notifyListeners();
  }

  /// Aplica las marcas de lectura a la lista recién traída del inbox: si el
  /// último mensaje de una conversación no es más nuevo que lo ya leído, se deja
  /// el contador en 0; si llegó algo más nuevo, se descarta la marca y se
  /// respeta el contador real del servidor.
  List<Conversation> _applyReadWatermarks(List<Conversation> convs) {
    if (_readWatermarks.isEmpty) return convs;

    return convs.map((c) {
      final watermark = _readWatermarks[c.participant2Id];
      if (watermark == null || c.unreadCount == 0) return c;

      final lastAt = c.lastMessage?.createdAt;
      // Llegó un mensaje más nuevo que el último leído: la marca ya no aplica.
      if (lastAt != null && lastAt.isAfter(watermark)) {
        _readWatermarks.remove(c.participant2Id);
        return c;
      }

      return Conversation(
        conversationId: c.conversationId,
        participant1Id: c.participant1Id,
        participant2Id: c.participant2Id,
        participant1Name: c.participant1Name,
        participant2Name: c.participant2Name,
        lastMessage: c.lastMessage,
        unreadCount: 0,
        updatedAt: c.updatedAt,
        otherUserRole: c.otherUserRole,
      );
    }).toList();
  }

  void startWatchingInbox() {
    if (_repository == null || _incomingMessageSubscription != null) return;
    _incomingMessageSubscription = _repository.messageStream.listen((_) {
      if (_currentUserId != null) {
        loadConversations(_currentUserId!);
      }
    });
  }

  void stopWatchingInbox() {
    _incomingMessageSubscription?.cancel();
    _incomingMessageSubscription = null;
  }

  @override
  void dispose() {
    stopWatchingInbox();
    super.dispose();
  }
}
