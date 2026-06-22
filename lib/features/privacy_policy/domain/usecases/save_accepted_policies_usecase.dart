import '../../data/models/accepted_policy_model.dart';
import '../repositories/privacy_policy_repository.dart';

class SaveAcceptedPoliciesUseCase {
  final PrivacyPolicyRepository repository;

  SaveAcceptedPoliciesUseCase({required this.repository});

  Future<void> execute(List<AcceptedPolicyModel> policies) {
    return repository.saveAcceptedPolicies(policies);
  }
}
