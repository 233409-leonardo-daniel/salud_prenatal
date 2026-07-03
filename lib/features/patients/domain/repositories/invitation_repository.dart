abstract class InvitationRepository {
  Future<Map<String, dynamic>> generateInvitationCode(int doctorId);
  Future<Map<String, dynamic>> redeemCode(int patientId, String code);
}
