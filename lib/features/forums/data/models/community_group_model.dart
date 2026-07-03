import '../../domain/entities/community_group.dart';

class CommunityGroupModel extends CommunityGroup {
  CommunityGroupModel({
    required super.groupId,
    required super.name,
    required super.description,
    required super.createdBy,
    required super.createdAt,
  });

  factory CommunityGroupModel.fromJson(Map<String, dynamic> json) {
    return CommunityGroupModel(
      groupId: json['group_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'created_by': createdBy,
    };
  }

  factory CommunityGroupModel.fromEntity(CommunityGroup entity) {
    return CommunityGroupModel(
      groupId: entity.groupId,
      name: entity.name,
      description: entity.description,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}
