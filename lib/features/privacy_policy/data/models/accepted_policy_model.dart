class AcceptedPolicyModel {
  final String policyId;
  final String policyTitle;
  final String userEmail;
  final String acceptedAt;

  AcceptedPolicyModel({
    required this.policyId,
    required this.policyTitle,
    required this.userEmail,
    required this.acceptedAt,
  });

  Map<String, dynamic> toJson() => {
        'policyId': policyId,
        'policyTitle': policyTitle,
        'userEmail': userEmail,
        'acceptedAt': acceptedAt,
      };

  factory AcceptedPolicyModel.fromJson(Map<String, dynamic> json) {
    return AcceptedPolicyModel(
      policyId: json['policyId'] as String,
      policyTitle: json['policyTitle'] as String,
      userEmail: json['userEmail'] as String,
      acceptedAt: json['acceptedAt'] as String,
    );
  }
}
