import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accepted_policy_model.dart';

abstract class PrivacyPolicyLocalDataSource {
  Future<void> saveAcceptedPolicies(List<AcceptedPolicyModel> policies);
  Future<List<AcceptedPolicyModel>> getAcceptedPolicies(String userEmail);
}

class PrivacyPolicyLocalDataSourceImpl implements PrivacyPolicyLocalDataSource {
  static const String _storageKey = 'accepted_policies';

  @override
  Future<void> saveAcceptedPolicies(List<AcceptedPolicyModel> policies) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    for (final policy in policies) {
      existing.add(jsonEncode(policy.toJson()));
    }

    await prefs.setStringList(_storageKey, existing);
  }

  @override
  Future<List<AcceptedPolicyModel>> getAcceptedPolicies(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? [];

    final allPolicies = stored
        .map((json) => AcceptedPolicyModel.fromJson(jsonDecode(json)))
        .toList();

    return allPolicies
        .where((p) => p.userEmail == userEmail)
        .toList();
  }
}
