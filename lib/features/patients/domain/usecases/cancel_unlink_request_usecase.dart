import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class CancelUnlinkRequestUsecase {
  final UnlinkRequestRepository repository;
  CancelUnlinkRequestUsecase(this.repository);

  Future<UnlinkRequestEntity> call(int patientId, int requestId) =>
      repository.cancelRequest(patientId, requestId);
}
