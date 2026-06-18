class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      tokenType: json['token_type'] ?? json['tokenType'] ?? 'bearer',
      userId: json['user_id'] ?? json['userId'] ?? 0,
      role: json['role'] ?? 'patient',
    );
  }
}
