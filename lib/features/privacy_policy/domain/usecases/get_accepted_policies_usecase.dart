import '../entities/accepted_policy.dart';
import '../repositories/privacy_policy_repository.dart';

class GetAcceptedPoliciesUseCase {
  final PrivacyPolicyRepository repository;

  GetAcceptedPoliciesUseCase({required this.repository});

  Future<List<AcceptedPolicy>> execute(String userEmail) {
    return repository.getAcceptedPolicies(userEmail);
  }
}
