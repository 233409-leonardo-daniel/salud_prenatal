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
  final String? specialty;
  final String? professionalLicense;
  final String? office;

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
    this.specialty,
    this.professionalLicense,
    this.office,
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
      specialty: json['specialty'],
      professionalLicense: json['professional_license'] ?? json['professionalLicense'],
      office: json['office'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
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
      'specialty': specialty,
      'professional_license': professionalLicense,
      'office': office,
    };
    // Solo se envía la contraseña cuando se está creando/cambiando de forma
    // explícita. Un update de perfil pasa password == null y omite la clave,
    // para no blanquear la credencial en el backend.
    if (password != null) {
      map['password'] = password;
    }
    return map;
  }
}
