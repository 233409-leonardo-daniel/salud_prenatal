import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class CreateUnlinkRequestUsecase {
  final UnlinkRequestRepository repository;
  CreateUnlinkRequestUsecase(this.repository);

  Future<UnlinkRequestEntity> call(int patientId, String? reason) =>
      repository.createRequest(patientId, reason);
}
