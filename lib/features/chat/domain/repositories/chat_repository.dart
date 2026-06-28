import '../entities/chat_message.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  Future<List<Conversation>> getConversations(int currentUserId);
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId);
  Stream<ChatMessage> get messageStream;
  Stream<bool> get connectionStatusStream;
  Future<void> connect(int currentUserId);
  void sendMessage(int receiverId, String content);
  void disconnect();
}
