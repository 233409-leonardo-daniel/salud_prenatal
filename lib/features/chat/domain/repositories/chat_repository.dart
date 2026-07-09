import '../entities/chat_contact.dart';
import '../entities/chat_message.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  /// Construye la lista de conversaciones a partir de [contacts] (personas
  /// reales con las que el usuario puede chatear), consultando el historial
  /// de cada una en paralelo. Solo se devuelven conversaciones con al menos
  /// un mensaje real.
  Future<List<Conversation>> getConversations(int currentUserId, List<ChatContact> contacts);
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId);
  Stream<ChatMessage> get messageStream;
  Stream<bool> get connectionStatusStream;
  Future<void> connect(int currentUserId);
  void sendMessage(int receiverId, String content);
  void disconnect();
}
