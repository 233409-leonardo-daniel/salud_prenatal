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

  /// Igual que en `ForumPost`: el backend solo devuelve `author_id` en
  /// `CommentResponse`, así que el alias/avatar se resuelven en el cliente.
  ForumComment copyWithAuthorInfo({
    String? authorAlias,
    String? authorAvatarUrl,
  }) {
    return ForumComment(
      commentId: commentId,
      postId: postId,
      authorId: authorId,
      content: content,
      createdAt: createdAt,
      authorAlias: authorAlias ?? this.authorAlias,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    );
  }
}
