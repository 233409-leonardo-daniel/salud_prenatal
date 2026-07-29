import '../repositories/invitation_repository.dart';

class RedeemInvitationCodeUsecase {
  final InvitationRepository repository;

  RedeemInvitationCodeUsecase(this.repository);

  Future<Map<String, dynamic>> call(int patientId, String code) async {
    return await repository.redeemCode(patientId, code);
  }
}
