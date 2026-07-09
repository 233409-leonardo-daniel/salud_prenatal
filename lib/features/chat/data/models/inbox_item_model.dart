import '../../domain/entities/chat_message.dart';
import 'chat_message_model.dart';

class InboxItemModel {
  final int otherUserId;
  final String otherUserName;
  final String otherUserLastname;
  final String otherUserRole;
  final ChatMessage? lastMessage;
  final int unreadCount;

  InboxItemModel({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserLastname,
    required this.otherUserRole,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory InboxItemModel.fromJson(Map<String, dynamic> json) {
    return InboxItemModel(
      otherUserId: json['other_user_id'] ?? 0,
      otherUserName: json['other_user_name'] ?? '',
      otherUserLastname: json['other_user_lastname'] ?? '',
      otherUserRole: json['other_user_role'] ?? '',
      lastMessage: json['last_message'] != null
          ? ChatMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
