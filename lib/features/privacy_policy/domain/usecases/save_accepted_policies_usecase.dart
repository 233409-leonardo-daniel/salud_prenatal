import '../entities/accepted_policy.dart';
import '../repositories/privacy_policy_repository.dart';

class SaveAcceptedPoliciesUsecase {
  final PrivacyPolicyRepository repository;

  SaveAcceptedPoliciesUsecase({required this.repository});

  Future<void> execute(List<AcceptedPolicy> policies) {
    return repository.saveAcceptedPolicies(policies);
  }
}
