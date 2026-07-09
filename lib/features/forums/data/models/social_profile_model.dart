import '../../domain/entities/social_profile.dart';

class SocialProfileModel extends SocialProfile {
  SocialProfileModel({
    required super.userId,
    required super.alias,
    super.bio,
    super.avatarUrl,
    super.officeAddress,
  });

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      userId: json['user_id'] ?? json['id'] ?? 0,
      alias: json['alias'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      officeAddress: json['office_address'],
    );
  }

  // user_id ya no se manda: el backend lo deriva del token JWT.
  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      'bio': bio,
      'avatar_url': avatarUrl,
      'office_address': officeAddress,
    };
  }

  factory SocialProfileModel.fromEntity(SocialProfile entity) {
    return SocialProfileModel(
      userId: entity.userId,
      alias: entity.alias,
      bio: entity.bio,
      avatarUrl: entity.avatarUrl,
      officeAddress: entity.officeAddress,
    );
  }
}
