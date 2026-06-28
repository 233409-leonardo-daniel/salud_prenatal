class UserProfile {
  final int? userId;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final String phone;
  final String imageUrl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? password;

  UserProfile({
    this.userId,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone = '',
    this.imageUrl = '',
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
    this.password,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['id'] ?? json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      updatedAt: json['updated_at'] ?? json['updatedAt'] ?? '',
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'last_name': lastName,
      'email': email,
      'role': role,
      'phone': phone,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.isNotEmpty ? createdAt : DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'password': password ?? '',
    };
  }
}
