import '../../../login/domain/entities/user_profile.dart';
import '../entities/chat_message.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  /// Trae la bandeja de conversaciones real desde GET /chat/inbox.
  Future<List<Conversation>> getConversations(int currentUserId);
  /// Trae "con quién puedo empezar a chatear" desde GET /chat/contacts — el
  /// backend resuelve la lista según el rol del JWT (patients/doctores/
  /// recepcionistas), sin parámetros del lado del cliente.
  Future<List<UserProfile>> getContacts();
  Future<List<ChatMessage>> getChatHistory(int otherUserId, int currentUserId);
  Stream<ChatMessage> get messageStream;
  Stream<bool> get connectionStatusStream;
  Future<void> connect(int currentUserId);

  /// Envía un mensaje por el WebSocket. Devuelve `true` si se pudo escribir
  /// sobre un socket abierto, `false` si no había conexión.
  bool sendMessage(int receiverId, String content);
  void disconnect();
}
