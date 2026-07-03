import '../entities/chat_contact.dart';
import '../entities/conversation_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository repository;

  GetConversationsUseCase(this.repository);

  Future<List<Conversation>> call(int currentUserId, List<ChatContact> contacts) async {
    return await repository.getConversations(currentUserId, contacts);
  }
}
