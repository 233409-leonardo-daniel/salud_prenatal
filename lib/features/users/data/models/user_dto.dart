class UserDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? profilePicture;

  UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.profilePicture,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    final lastName = json['last_name'] ?? '';
    final combinedName = json['full_name'] ?? (name.isNotEmpty || lastName.isNotEmpty ? '$name $lastName'.trim() : '');
    return UserDto(
      id: json['user_id'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: combinedName.toString(),
      role: json['role'] ?? '',
      phoneNumber: json['phone'] ?? json['phone_number'],
      profilePicture: json['image_url'] ?? json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
    };
  }
}
