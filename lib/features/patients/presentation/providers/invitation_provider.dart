import 'package:flutter/foundation.dart';
import '../../data/datasources/invitation_remote_data_source.dart';
import '../pages/patient_state.dart';

class InvitationProvider with ChangeNotifier {
  final InvitationRemoteDataSource _dataSource;

  InvitationProvider({required InvitationRemoteDataSource dataSource})
      : _dataSource = dataSource;

  InvitationCodeStatus _generateStatus = InvitationCodeStatus.initial;
  InvitationCodeStatus _redeemStatus = InvitationCodeStatus.initial;
  String? _generatedCode;
  String? _expiresAt;
  String? _error;

  InvitationCodeStatus get generateStatus => _generateStatus;
  InvitationCodeStatus get redeemStatus => _redeemStatus;
  String? get generatedCode => _generatedCode;
  String? get expiresAt => _expiresAt;
  String? get error => _error;

  Future<void> generateInvitationCode(int doctorId) async {
    _generateStatus = InvitationCodeStatus.loading;
    _error = null;
    _generatedCode = null;
    _expiresAt = null;
    notifyListeners();

    try {
      final result = await _dataSource.generateInvitationCode(doctorId);
      _generatedCode = result['code'] as String?;
      _expiresAt = result['expires_at']?.toString();
      _generateStatus = InvitationCodeStatus.success;
    } catch (e) {
      _generateStatus = InvitationCodeStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> redeemCode(int patientId, String code) async {
    _redeemStatus = InvitationCodeStatus.loading;
    _error = null;
    notifyListeners();

    try {
      await _dataSource.redeemCode(patientId, code);
      _redeemStatus = InvitationCodeStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _redeemStatus = InvitationCodeStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _generateStatus = InvitationCodeStatus.initial;
    _redeemStatus = InvitationCodeStatus.initial;
    _generatedCode = null;
    _expiresAt = null;
    _error = null;
    notifyListeners();
  }
}
