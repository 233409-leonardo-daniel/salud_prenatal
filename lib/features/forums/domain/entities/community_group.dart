class CommunityGroup {
  final int groupId;
  final String name;
  final String description;
  final int createdBy;
  final DateTime createdAt;
  final String? clusterTag;

  CommunityGroup({
    required this.groupId,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.clusterTag,
  });
}
