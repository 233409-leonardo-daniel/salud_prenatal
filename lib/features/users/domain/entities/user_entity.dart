class UserEntity {
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

  /// `false` cuando la cuenta fue suspendida/baneada por un administrador
  /// (campo `is_active` del backend). Por defecto true: si el dato no viene,
  /// no se asume baneo.
  final bool isActive;

  UserEntity({
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
    this.isActive = true,
  });
}
