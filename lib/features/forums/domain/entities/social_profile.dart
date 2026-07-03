class SocialProfile {
  final int userId;
  final String alias;
  final String? bio;
  final String? avatarUrl;
  final String? officeAddress;
  final String? clusterProfile;

  SocialProfile({
    required this.userId,
    required this.alias,
    this.bio,
    this.avatarUrl,
    this.officeAddress,
    this.clusterProfile,
  });
}
