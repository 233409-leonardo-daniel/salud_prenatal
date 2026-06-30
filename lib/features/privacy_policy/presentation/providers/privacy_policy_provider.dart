import 'package:flutter/foundation.dart';
import '../../data/models/accepted_policy_model.dart';
import '../../domain/usecases/save_accepted_policies_usecase.dart';
import '../../domain/usecases/get_accepted_policies_usecase.dart';
import '../pages/privacy_policy_state.dart';

class PrivacyPolicyProvider with ChangeNotifier {
  final SaveAcceptedPoliciesUseCase _saveAcceptedPoliciesUseCase;
  final GetAcceptedPoliciesUseCase _getAcceptedPoliciesUseCase;

  PrivacyPolicyProvider({
    required SaveAcceptedPoliciesUseCase saveAcceptedPoliciesUseCase,
    required GetAcceptedPoliciesUseCase getAcceptedPoliciesUseCase,
  })  : _saveAcceptedPoliciesUseCase = saveAcceptedPoliciesUseCase,
        _getAcceptedPoliciesUseCase = getAcceptedPoliciesUseCase;

  List<AcceptedPolicyModel> _acceptedPolicies = [];
  List<AcceptedPolicyModel> get acceptedPolicies => _acceptedPolicies;

  PrivacyPolicyStatus _status = PrivacyPolicyStatus.initial;
  PrivacyPolicyStatus get status => _status;
  bool get isLoading => _status == PrivacyPolicyStatus.loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> saveAcceptedPolicies({
    required String userEmail,
    required bool acceptedPrivacy,
    required bool acceptedSensitiveData,
  }) async {
    _status = PrivacyPolicyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      final policies = <AcceptedPolicyModel>[];

      if (acceptedPrivacy) {
        policies.add(AcceptedPolicyModel(
          policyId: 'privacy_policy_v1',
          policyTitle: 'Aviso de Privacidad Integral',
          userEmail: userEmail,
          acceptedAt: now,
        ));
      }

      if (acceptedSensitiveData) {
        policies.add(AcceptedPolicyModel(
          policyId: 'sensitive_data_v1',
          policyTitle: 'Consentimiento de Datos Personales Sensibles',
          userEmail: userEmail,
          acceptedAt: now,
        ));
      }

      await _saveAcceptedPoliciesUseCase.execute(policies);
      _status = PrivacyPolicyStatus.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _status = PrivacyPolicyStatus.error;
      notifyListeners();
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
