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
    super.isAd,
    super.imageUrl,
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
      isAd: json['is_ad'] == true,
      imageUrl: json['image_url'],
    );
  }

  // author_id ya no se manda: el backend lo deriva del token JWT.
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'title': title,
      'content': content,
      'is_ad': isAd,
      // Solo se envía image_url cuando hay una URL real, para no mandar
      // null/"" y que el backend guarde una imagen vacía.
      if (imageUrl != null && imageUrl!.trim().isNotEmpty)
        'image_url': imageUrl!.trim(),
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
      isAd: entity.isAd,
      imageUrl: entity.imageUrl,
    );
  }
}
