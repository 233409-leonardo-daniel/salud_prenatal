class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String role;
  final int? patientId;
  final int? doctorId;
  final int? medicalRecordId;
  final String? subscriptionStatus;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.role,
    this.patientId,
    this.doctorId,
    this.medicalRecordId,
    this.subscriptionStatus,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      tokenType: json['token_type'] ?? json['tokenType'] ?? 'bearer',
      userId: json['user_id'] ?? json['userId'] ?? 0,
      role: json['role'] ?? 'patient',
      patientId: json['patient_id'] ?? json['patientId'],
      doctorId: json['doctor_id'] ?? json['doctorId'],
      medicalRecordId: json['medical_record_id'] ?? json['medicalRecordId'],
      subscriptionStatus: json['subscription_status'] ?? json['subscriptionStatus'],
    );
  }
}
