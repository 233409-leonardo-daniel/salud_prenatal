import 'package:flutter/foundation.dart';
import '../../data/models/accepted_policy_model.dart';
import '../../domain/usecases/save_accepted_policies_usecase.dart';
import '../../domain/usecases/get_accepted_policies_usecase.dart';

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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> saveAcceptedPolicies({
    required String userEmail,
    required bool acceptedPrivacy,
    required bool acceptedSensitiveData,
  }) async {
    _isLoading = true;
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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAcceptedPolicies(String userEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _acceptedPolicies = await _getAcceptedPoliciesUseCase.execute(userEmail);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
