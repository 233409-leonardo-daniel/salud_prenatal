import '../models/accepted_policy_model.dart';
import '../../domain/repositories/privacy_policy_repository.dart';
import '../datasources/privacy_policy_local_data_source.dart';

class PrivacyPolicyRepositoryImpl implements PrivacyPolicyRepository {
  final PrivacyPolicyLocalDataSource localDataSource;

  PrivacyPolicyRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveAcceptedPolicies(List<AcceptedPolicyModel> policies) {
    return localDataSource.saveAcceptedPolicies(policies);
  }

  @override
  Future<List<AcceptedPolicyModel>> getAcceptedPolicies(String userEmail) {
    return localDataSource.getAcceptedPolicies(userEmail);
  }
}
