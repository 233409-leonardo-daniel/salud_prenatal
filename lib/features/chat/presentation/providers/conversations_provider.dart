import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/chat_contact.dart';
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
  List<ChatContact> _lastContacts = [];
  StreamSubscription<dynamic>? _incomingMessageSubscription;

  ConversationsViewState get viewState => _viewState;
  String? get error => _error;
  List<Conversation> get conversations => _conversations;

  /// Carga las conversaciones reales del usuario a partir de [contacts]: la
  /// lista de personas con las que puede chatear (pacientes del doctor, o el
  /// doctor asignado del paciente). El backend no tiene un endpoint de
  /// "inbox", así que esta lista debe venir ya resuelta desde la UI con
  /// datos reales, nunca con IDs inventados.
  Future<void> loadConversations(int currentUserId, List<ChatContact> contacts) async {
    _currentUserId = currentUserId;
    _lastContacts = contacts;
    _viewState = ConversationsViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _getConversationsUseCase.call(currentUserId, contacts);
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
  /// a [loadConversations] al menos una vez (para conocer el usuario actual
  /// y los contactos).
  void startWatchingInbox() {
    if (_repository == null || _incomingMessageSubscription != null) return;
    _incomingMessageSubscription = _repository.messageStream.listen((_) {
      if (_currentUserId != null) {
        loadConversations(_currentUserId!, _lastContacts);
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
