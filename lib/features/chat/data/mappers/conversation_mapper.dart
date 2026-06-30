import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/chat_message.dart';
import '../models/conversation_dto.dart';
import '../models/chat_message_model.dart'; // fallback if we don't refactor it yet

class ConversationMapper {
  static Conversation dtoToEntity(ConversationDto dto) {
    ChatMessage? lastMessageEntity;
    if (dto.lastMessage != null) {
      final msgModel = ChatMessageModel.fromJson(dto.lastMessage!);
      lastMessageEntity = msgModel; // assuming ChatMessageModel extends ChatMessage
    }

    return Conversation(
      conversationId: dto.id,
      participant1Id: dto.participant1Id,
      participant2Id: dto.participant2Id,
      participant1Name: dto.participant1Name,
      participant2Name: dto.participant2Name,
      lastMessage: lastMessageEntity,
      unreadCount: dto.unreadCount,
      updatedAt: DateTime.tryParse(dto.updatedAt) ?? DateTime.now(),
    );
  }
}
