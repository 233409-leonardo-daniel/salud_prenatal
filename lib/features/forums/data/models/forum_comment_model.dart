import '../../domain/entities/forum_comment.dart';

class ForumCommentModel extends ForumComment {
  ForumCommentModel({
    required super.commentId,
    required super.postId,
    required super.authorId,
    required super.content,
    required super.createdAt,
    super.authorAlias,
    super.authorAvatarUrl,
  });

  factory ForumCommentModel.fromJson(Map<String, dynamic> json) {
    return ForumCommentModel(
      commentId: json['comment_id'] ?? json['id'] ?? 0,
      postId: json['post_id'] ?? 0,
      authorId: json['author_id'] ?? 0,
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authorAlias: json['author_alias'] ?? json['alias'],
      authorAvatarUrl: json['author_avatar_url'] ?? json['avatar_url'],
    );
  }

  // author_id ya no se manda: el backend lo deriva del token JWT.
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'content': content,
    };
  }

  factory ForumCommentModel.fromEntity(ForumComment entity) {
    return ForumCommentModel(
      commentId: entity.commentId,
      postId: entity.postId,
      authorId: entity.authorId,
      content: entity.content,
      createdAt: entity.createdAt,
      authorAlias: entity.authorAlias,
      authorAvatarUrl: entity.authorAvatarUrl,
    );
  }
}
