class ForumComment {
  final int commentId;
  final int postId;
  final int authorId;
  final String content;
  final DateTime createdAt;
  final String? authorAlias;
  final String? authorAvatarUrl;

  ForumComment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorAlias,
    this.authorAvatarUrl,
  });
}
