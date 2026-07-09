class ForumPost {
  final int postId;
  final int authorId;
  final int? groupId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? authorAlias;
  final String? authorAvatarUrl;
  final String? authorRole;
  final bool isAd;

  ForumPost({
    required this.postId,
    required this.authorId,
    this.groupId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.authorAlias,
    this.authorAvatarUrl,
    this.authorRole,
    this.isAd = false,
  });
}
