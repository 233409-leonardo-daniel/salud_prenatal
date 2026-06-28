
class ConversationDto {
  final int id;
  final int participant1Id;
  final int participant2Id;
  final String participant1Name;
  final String participant2Name;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;
  final String updatedAt;

  ConversationDto({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.participant1Name,
    required this.participant2Name,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json['id'] ?? 0,
      participant1Id: json['participant_1_id'] ?? 0,
      participant2Id: json['participant_2_id'] ?? 0,
      participant1Name: json['participant_1_name'] ?? '',
      participant2Name: json['participant_2_name'] ?? '',
      lastMessage: json['last_message'],
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_1_id': participant1Id,
      'participant_2_id': participant2Id,
      'participant_1_name': participant1Name,
      'participant_2_name': participant2Name,
      'last_message': lastMessage,
      'unread_count': unreadCount,
      'updated_at': updatedAt,
    };
  }
}
