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
