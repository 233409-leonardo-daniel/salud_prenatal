import '../entities/accepted_policy.dart';
import '../repositories/privacy_policy_repository.dart';

class SaveAcceptedPoliciesUseCase {
  final PrivacyPolicyRepository repository;

  SaveAcceptedPoliciesUseCase({required this.repository});

  Future<void> execute(List<AcceptedPolicy> policies) {
    return repository.saveAcceptedPolicies(policies);
  }
}
