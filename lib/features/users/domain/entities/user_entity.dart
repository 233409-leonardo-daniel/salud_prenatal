class UserEntity {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? profilePicture;
  final int? doctorId;

  UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.profilePicture,
    this.doctorId,
  });
}
