class UserProfile {
  final int? userId;
  final String name;
  final String lastName;
  final String email;
  final String role;

  UserProfile({
    this.userId,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] ?? json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
