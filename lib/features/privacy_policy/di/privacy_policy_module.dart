import '../data/datasources/privacy_policy_local_data_source.dart';
import '../data/repositories/privacy_policy_repository_impl.dart';
import '../domain/repositories/privacy_policy_repository.dart';
import '../domain/usecases/save_accepted_policies_usecase.dart';
import '../domain/usecases/get_accepted_policies_usecase.dart';

class PrivacyPolicyModule {
  late final PrivacyPolicyRepository repository;
  late final SaveAcceptedPoliciesUseCase saveAcceptedPoliciesUseCase;
  late final GetAcceptedPoliciesUseCase getAcceptedPoliciesUseCase;

  PrivacyPolicyModule() {
    _initDependencies();
  }

  void _initDependencies() {
    final localDataSource = PrivacyPolicyLocalDataSourceImpl();
    repository = PrivacyPolicyRepositoryImpl(localDataSource: localDataSource);
    saveAcceptedPoliciesUseCase =
        SaveAcceptedPoliciesUseCase(repository: repository);
    getAcceptedPoliciesUseCase =
        GetAcceptedPoliciesUseCase(repository: repository);
  }
}
