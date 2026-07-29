import 'package:flutter/foundation.dart';
import '../../domain/entities/accepted_policy.dart';
import '../../domain/usecases/save_accepted_policies_usecase.dart';
import '../../domain/usecases/get_accepted_policies_usecase.dart';
import '../pages/privacy_policy_state.dart';

class PrivacyPolicyProvider with ChangeNotifier {
  final SaveAcceptedPoliciesUsecase _saveAcceptedPoliciesUseCase;
  final GetAcceptedPoliciesUsecase _getAcceptedPoliciesUseCase;

  PrivacyPolicyProvider({
    required SaveAcceptedPoliciesUsecase saveAcceptedPoliciesUseCase,
    required GetAcceptedPoliciesUsecase getAcceptedPoliciesUseCase,
  })  : _saveAcceptedPoliciesUseCase = saveAcceptedPoliciesUseCase,
        _getAcceptedPoliciesUseCase = getAcceptedPoliciesUseCase;

  List<AcceptedPolicy> _acceptedPolicies = [];
  List<AcceptedPolicy> get acceptedPolicies => _acceptedPolicies;

  PrivacyPolicyStatus _status = PrivacyPolicyStatus.initial;
  PrivacyPolicyStatus get status => _status;
  bool get isLoading => _status == PrivacyPolicyStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> saveAcceptedPolicies({
    required String userEmail,
    required bool acceptedPrivacy,
    required bool acceptedSensitiveData,
  }) async {
    _status = PrivacyPolicyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      final policies = <AcceptedPolicy>[];

      if (acceptedPrivacy) {
        policies.add(AcceptedPolicy(
          policyId: 'privacy_policy_v1',
          policyTitle: 'Aviso de Privacidad Integral',
          userEmail: userEmail,
          acceptedAt: now,
        ));
      }

      if (acceptedSensitiveData) {
        policies.add(AcceptedPolicy(
          policyId: 'sensitive_data_v1',
          policyTitle: 'Consentimiento de Datos Personales Sensibles',
          userEmail: userEmail,
          acceptedAt: now,
        ));
      }

      await _saveAcceptedPoliciesUseCase.execute(policies);
      _status = PrivacyPolicyStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = PrivacyPolicyStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAcceptedPolicies(String userEmail) async {
    _status = PrivacyPolicyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _acceptedPolicies = await _getAcceptedPoliciesUseCase.execute(userEmail);
      _status = PrivacyPolicyStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = PrivacyPolicyStatus.error;
      notifyListeners();
    }
  }
}
