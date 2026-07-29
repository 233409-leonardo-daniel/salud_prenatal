import '../repositories/invitation_repository.dart';

class GenerateInvitationCodeUsecase {
  final InvitationRepository repository;

  GenerateInvitationCodeUsecase(this.repository);

  Future<Map<String, dynamic>> call(int doctorId) async {
    return await repository.generateInvitationCode(doctorId);
  }
}
