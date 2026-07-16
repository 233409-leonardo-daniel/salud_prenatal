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

  /// El backend no incluye alias/avatar/rol del autor en `PostResponse` (solo
  /// `author_id`): esto permite completarlos del lado del cliente resolviendo
  /// el perfil social + usuario, sin tocar el backend.
  ForumPost copyWithAuthorInfo({
    String? authorAlias,
    String? authorAvatarUrl,
    String? authorRole,
  }) {
    return ForumPost(
      postId: postId,
      authorId: authorId,
      groupId: groupId,
      title: title,
      content: content,
      createdAt: createdAt,
      authorAlias: authorAlias ?? this.authorAlias,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorRole: authorRole ?? this.authorRole,
      isAd: isAd,
    );
  }
}
