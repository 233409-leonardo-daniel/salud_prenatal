import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class ResolveUnlinkRequestUseCase {
  final UnlinkRequestRepository repository;
  ResolveUnlinkRequestUseCase(this.repository);

  /// [status] debe ser 'approved' o 'rejected'.
  Future<UnlinkRequestEntity> call(int doctorId, int requestId, String status) =>
      repository.resolveRequest(doctorId, requestId, status);
}
