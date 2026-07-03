import '../../domain/entities/social_profile.dart';

class SocialProfileModel extends SocialProfile {
  SocialProfileModel({
    required super.userId,
    required super.alias,
    super.bio,
    super.avatarUrl,
    super.officeAddress,
    super.clusterProfile,
  });

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      userId: json['user_id'] ?? json['id'] ?? 0,
      alias: json['alias'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      officeAddress: json['office_address'],
      clusterProfile: json['cluster_profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'alias': alias,
      'bio': bio,
      'avatar_url': avatarUrl,
      'office_address': officeAddress,
      'cluster_profile': clusterProfile,
    };
  }

  factory SocialProfileModel.fromEntity(SocialProfile entity) {
    return SocialProfileModel(
      userId: entity.userId,
      alias: entity.alias,
      bio: entity.bio,
      avatarUrl: entity.avatarUrl,
      officeAddress: entity.officeAddress,
      clusterProfile: entity.clusterProfile,
    );
  }
}
