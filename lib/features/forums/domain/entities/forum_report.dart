class ForumReport {
  final int? reportId;
  final int reporterId;
  final int? postId;
  final int? commentId;
  final String reason;
  final DateTime? createdAt;

  ForumReport({
    this.reportId,
    required this.reporterId,
    this.postId,
    this.commentId,
    required this.reason,
    this.createdAt,
  });
}
