class ChatMessage {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });
}
