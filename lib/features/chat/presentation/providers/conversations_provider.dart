import 'package:flutter/foundation.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/get_conversations_use_case.dart';

enum ConversationsViewState { initial, loading, success, error }

class ConversationsProvider with ChangeNotifier {
  final GetConversationsUseCase _getConversationsUseCase;

  ConversationsProvider(this._getConversationsUseCase);

  ConversationsViewState _viewState = ConversationsViewState.initial;
  String? _error;
  List<Conversation> _conversations = [];

  ConversationsViewState get viewState => _viewState;
  String? get error => _error;
  List<Conversation> get conversations => _conversations;

  Future<void> loadConversations(int currentUserId) async {
    _viewState = ConversationsViewState.loading;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _getConversationsUseCase.call(currentUserId);
      _viewState = ConversationsViewState.success;
    } catch (e) {
      _viewState = ConversationsViewState.error;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }
}
