import '../models/accepted_policy_model.dart';
import '../../domain/entities/accepted_policy.dart';
import '../../domain/repositories/privacy_policy_repository.dart';
import '../datasources/privacy_policy_local_data_source.dart';

class PrivacyPolicyRepositoryImpl implements PrivacyPolicyRepository {
  final PrivacyPolicyLocalDataSource localDataSource;

  PrivacyPolicyRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveAcceptedPolicies(List<AcceptedPolicy> policies) {
    final models = policies.map(AcceptedPolicyModel.fromEntity).toList();
    return localDataSource.saveAcceptedPolicies(models);
  }

  @override
  Future<List<AcceptedPolicy>> getAcceptedPolicies(String userEmail) {
    return localDataSource.getAcceptedPolicies(userEmail);
  }
}
