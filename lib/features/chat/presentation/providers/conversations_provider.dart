import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_conversations_use_case.dart';

enum ConversationsViewState { initial, loading, success, error }

class ConversationsProvider with ChangeNotifier {
  final GetConversationsUseCase _getConversationsUseCase;
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
      _conversations = result;
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
    if (idx == -1 || _conversations[idx].unreadCount == 0) return;

    final old = _conversations[idx];
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
