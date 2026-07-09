import 'chat_message.dart';

class Conversation {
  final int conversationId;
  final int participant1Id;
  final int participant2Id;
  final String participant1Name;
  final String participant2Name;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  // Viene directo de /chat/inbox (other_user_role): permite pintar la fila
  // (prefijo "Dra.", badge de recepcionista, etc.) sin resolver el rol vía
  // dashboardProvider.users.
  final String otherUserRole;

  Conversation({
    required this.conversationId,
    required this.participant1Id,
    required this.participant2Id,
    required this.participant1Name,
    required this.participant2Name,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.otherUserRole = '',
  });
}
