import '../../data/models/accepted_policy_model.dart';
import '../repositories/privacy_policy_repository.dart';

class GetAcceptedPoliciesUseCase {
  final PrivacyPolicyRepository repository;

  GetAcceptedPoliciesUseCase({required this.repository});

  Future<List<AcceptedPolicyModel>> execute(String userEmail) {
    return repository.getAcceptedPolicies(userEmail);
  }
}
