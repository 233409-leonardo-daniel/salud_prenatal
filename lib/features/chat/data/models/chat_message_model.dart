import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.messageId,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.createdAt,
    required super.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['message_id'] ?? json['messageId'] ?? 0,
      senderId: json['sender_id'] ?? json['senderId'] ?? 0,
      receiverId: json['receiver_id'] ?? json['receiverId'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
