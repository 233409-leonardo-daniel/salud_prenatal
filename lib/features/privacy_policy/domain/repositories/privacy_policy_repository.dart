import '../../data/models/accepted_policy_model.dart';

abstract class PrivacyPolicyRepository {
  Future<void> saveAcceptedPolicies(List<AcceptedPolicyModel> policies);
  Future<List<AcceptedPolicyModel>> getAcceptedPolicies(String userEmail);
}
