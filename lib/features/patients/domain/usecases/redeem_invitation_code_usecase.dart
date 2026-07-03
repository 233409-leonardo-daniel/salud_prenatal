import '../repositories/invitation_repository.dart';

class RedeemInvitationCodeUseCase {
  final InvitationRepository repository;

  RedeemInvitationCodeUseCase(this.repository);

  Future<Map<String, dynamic>> call(int patientId, String code) async {
    return await repository.redeemCode(patientId, code);
  }
}
