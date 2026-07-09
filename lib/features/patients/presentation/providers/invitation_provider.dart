import 'package:flutter/foundation.dart';
import '../../domain/usecases/generate_invitation_code_usecase.dart';
import '../../domain/usecases/redeem_invitation_code_usecase.dart';
import '../pages/patient_state.dart';

class InvitationProvider with ChangeNotifier {
  final GenerateInvitationCodeUseCase _generateInvitationCodeUseCase;
  final RedeemInvitationCodeUseCase _redeemInvitationCodeUseCase;

  InvitationProvider({
    required GenerateInvitationCodeUseCase generateInvitationCodeUseCase,
    required RedeemInvitationCodeUseCase redeemInvitationCodeUseCase,
  })  : _generateInvitationCodeUseCase = generateInvitationCodeUseCase,
        _redeemInvitationCodeUseCase = redeemInvitationCodeUseCase;

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
      final result = await _generateInvitationCodeUseCase.call(doctorId);
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
      await _redeemInvitationCodeUseCase.call(patientId, code);
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
