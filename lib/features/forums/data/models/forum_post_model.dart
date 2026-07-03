import '../../domain/entities/forum_post.dart';

class ForumPostModel extends ForumPost {
  ForumPostModel({
    required super.postId,
    required super.authorId,
    super.groupId,
    required super.title,
    required super.content,
    required super.createdAt,
    super.authorAlias,
    super.authorAvatarUrl,
    super.authorRole,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      postId: json['post_id'] ?? json['id'] ?? 0,
      authorId: json['author_id'] ?? 0,
      groupId: json['group_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      authorAlias: json['author_alias'] ?? json['alias'],
      authorAvatarUrl: json['author_avatar_url'] ?? json['avatar_url'],
      authorRole: json['author_role'] ?? json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author_id': authorId,
      'group_id': groupId,
      'title': title,
      'content': content,
    };
  }

  factory ForumPostModel.fromEntity(ForumPost entity) {
    return ForumPostModel(
      postId: entity.postId,
      authorId: entity.authorId,
      groupId: entity.groupId,
      title: entity.title,
      content: entity.content,
      createdAt: entity.createdAt,
      authorAlias: entity.authorAlias,
      authorAvatarUrl: entity.authorAvatarUrl,
      authorRole: entity.authorRole,
    );
  }
}
