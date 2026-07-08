class UserDto {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? profilePicture;
  final int? doctorId;
  final String? specialty;
  final String? professionalLicense;
  final String? office;

  UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.profilePicture,
    this.doctorId,
    this.specialty,
    this.professionalLicense,
    this.office,
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
      doctorId: json['doctor_id'],
      specialty: json['specialty'],
      professionalLicense: json['professional_license'] ?? json['professionalLicense'],
      office: json['office'],
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
      'doctor_id': doctorId,
      'specialty': specialty,
      'professional_license': professionalLicense,
      'office': office,
    };
  }
}
