import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class CreateUnlinkRequestUseCase {
  final UnlinkRequestRepository repository;
  CreateUnlinkRequestUseCase(this.repository);

  Future<UnlinkRequestEntity> call(int patientId, String? reason) =>
      repository.createRequest(patientId, reason);
}
