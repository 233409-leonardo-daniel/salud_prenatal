import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class GetPatientUnlinkRequestsUseCase {
  final UnlinkRequestRepository repository;
  GetPatientUnlinkRequestsUseCase(this.repository);

  Future<List<UnlinkRequestEntity>> call(int patientId, {String? status}) =>
      repository.getPatientRequests(patientId, status: status);
}
