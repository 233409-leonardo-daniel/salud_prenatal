import '../repositories/invitation_repository.dart';

class GenerateInvitationCodeUseCase {
  final InvitationRepository repository;

  GenerateInvitationCodeUseCase(this.repository);

  Future<Map<String, dynamic>> call(int doctorId) async {
    return await repository.generateInvitationCode(doctorId);
  }
}
