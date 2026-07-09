class SocialProfile {
  final int userId;
  final String alias;
  final String? bio;
  final String? avatarUrl;
  final String? officeAddress;

  // cluster_profile ya no se expone: es un dato derivado de información
  // médica. El filtrado por cluster ocurre server-side (posts/recommended,
  // groups/recommended); el front no lo necesita ni debe mostrarlo.

  SocialProfile({
    required this.userId,
    required this.alias,
    this.bio,
    this.avatarUrl,
    this.officeAddress,
  });
}
