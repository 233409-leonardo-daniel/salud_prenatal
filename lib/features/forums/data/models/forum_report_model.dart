import '../../domain/entities/forum_report.dart';

class ForumReportModel extends ForumReport {
  ForumReportModel({
    super.reportId,
    required super.reporterId,
    super.postId,
    super.commentId,
    required super.reason,
    super.createdAt,
  });

  factory ForumReportModel.fromJson(Map<String, dynamic> json) {
    return ForumReportModel(
      reportId: json['report_id'] ?? json['id'],
      reporterId: json['reporter_id'] ?? 0,
      postId: json['post_id'],
      commentId: json['comment_id'],
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // reporter_id ya no se manda: el backend lo deriva del token JWT.
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'comment_id': commentId,
      'reason': reason,
    };
  }

  factory ForumReportModel.fromEntity(ForumReport entity) {
    return ForumReportModel(
      reportId: entity.reportId,
      reporterId: entity.reporterId,
      postId: entity.postId,
      commentId: entity.commentId,
      reason: entity.reason,
      createdAt: entity.createdAt,
    );
  }
}
