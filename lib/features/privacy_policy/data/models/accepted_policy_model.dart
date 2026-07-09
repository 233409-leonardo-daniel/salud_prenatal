import '../../domain/entities/accepted_policy.dart';

class AcceptedPolicyModel extends AcceptedPolicy {
  AcceptedPolicyModel({
    required super.policyId,
    required super.policyTitle,
    required super.userEmail,
    required super.acceptedAt,
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

  factory AcceptedPolicyModel.fromEntity(AcceptedPolicy policy) {
    return AcceptedPolicyModel(
      policyId: policy.policyId,
      policyTitle: policy.policyTitle,
      userEmail: policy.userEmail,
      acceptedAt: policy.acceptedAt,
    );
  }
}
