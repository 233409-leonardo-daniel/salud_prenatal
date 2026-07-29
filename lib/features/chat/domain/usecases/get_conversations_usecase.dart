import '../entities/conversation_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUsecase {
  final ChatRepository repository;

  GetConversationsUsecase(this.repository);

  Future<List<Conversation>> call(int currentUserId) async {
    return await repository.getConversations(currentUserId);
  }
}
