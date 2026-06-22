import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salud_prenatal/features/privacy_policy/data/datasources/privacy_policy_local_data_source.dart';
import 'package:salud_prenatal/features/privacy_policy/data/repositories/privacy_policy_repository_impl.dart';
import 'package:salud_prenatal/features/privacy_policy/domain/usecases/save_accepted_policies_usecase.dart';
import 'package:salud_prenatal/features/privacy_policy/domain/usecases/get_accepted_policies_usecase.dart';
import 'package:salud_prenatal/features/privacy_policy/presentation/providers/privacy_policy_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Privacy Policy Unit Tests', () {
    late PrivacyPolicyLocalDataSourceImpl localDataSource;
    late PrivacyPolicyRepositoryImpl repository;
    late SaveAcceptedPoliciesUseCase saveUseCase;
    late GetAcceptedPoliciesUseCase getUseCase;
    late PrivacyPolicyProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localDataSource = PrivacyPolicyLocalDataSourceImpl();
      repository = PrivacyPolicyRepositoryImpl(localDataSource: localDataSource);
      saveUseCase = SaveAcceptedPoliciesUseCase(repository: repository);
      getUseCase = GetAcceptedPoliciesUseCase(repository: repository);
      provider = PrivacyPolicyProvider(
        saveAcceptedPoliciesUseCase: saveUseCase,
        getAcceptedPoliciesUseCase: getUseCase,
      );
    });

    test('should save and load accepted policies correctly', () async {
      const email = 'test@example.com';
      await provider.saveAcceptedPolicies(
        userEmail: email,
        acceptedPrivacy: true,
        acceptedSensitiveData: true,
      );

      await provider.loadAcceptedPolicies(email);

      expect(provider.acceptedPolicies.length, 2);
      expect(provider.acceptedPolicies[0].policyId, 'privacy_policy_v1');
      expect(provider.acceptedPolicies[0].userEmail, email);
      expect(provider.acceptedPolicies[1].policyId, 'sensitive_data_v1');
      expect(provider.acceptedPolicies[1].userEmail, email);
    });

    test('should filter accepted policies by user email', () async {
      const email1 = 'user1@example.com';
      const email2 = 'user2@example.com';

      await provider.saveAcceptedPolicies(
        userEmail: email1,
        acceptedPrivacy: true,
        acceptedSensitiveData: false,
      );

      await provider.saveAcceptedPolicies(
        userEmail: email2,
        acceptedPrivacy: true,
        acceptedSensitiveData: true,
      );

      await provider.loadAcceptedPolicies(email1);
      expect(provider.acceptedPolicies.length, 1);
      expect(provider.acceptedPolicies[0].userEmail, email1);

      await provider.loadAcceptedPolicies(email2);
      expect(provider.acceptedPolicies.length, 2);
      expect(provider.acceptedPolicies.every((p) => p.userEmail == email2), true);
    });
  });
}
