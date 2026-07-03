import '../../domain/repositories/invitation_repository.dart';
import '../datasources/invitation_remote_data_source.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationRemoteDataSource remoteDataSource;

  const InvitationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> generateInvitationCode(int doctorId) {
    return remoteDataSource.generateInvitationCode(doctorId);
  }

  @override
  Future<Map<String, dynamic>> redeemCode(int patientId, String code) {
    return remoteDataSource.redeemCode(patientId, code);
  }
}
