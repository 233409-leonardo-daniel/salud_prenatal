import '../entities/accepted_policy.dart';

abstract class PrivacyPolicyRepository {
  Future<void> saveAcceptedPolicies(List<AcceptedPolicy> policies);
  Future<List<AcceptedPolicy>> getAcceptedPolicies(String userEmail);
}
