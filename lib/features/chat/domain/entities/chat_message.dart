/// Estado de entrega de un mensaje propio, usado por el envío optimista:
/// [sending] mientras esperamos que el servidor lo confirme (eco por WebSocket),
/// [sent] una vez confirmado, y [failed] si el socket no pudo mandarlo o no
/// llegó confirmación a tiempo. Los mensajes que vienen del historial/inbox
/// nacen como [sent].
enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  /// Estado de entrega (solo relevante para mensajes propios optimistas).
  final MessageStatus status;

  /// Identificador local temporal para casar el mensaje optimista con el eco
  /// del servidor. `null` en los mensajes que ya vienen persistidos.
  final String? clientId;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
    this.status = MessageStatus.sent,
    this.clientId,
  });

  ChatMessage copyWith({
    int? messageId,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    MessageStatus? status,
    String? clientId,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
    );
  }
}
