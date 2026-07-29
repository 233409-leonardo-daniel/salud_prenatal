import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class GetPatientUnlinkRequestsUsecase {
  final UnlinkRequestRepository repository;
  GetPatientUnlinkRequestsUsecase(this.repository);

  Future<List<UnlinkRequestEntity>> call(int patientId, {String? status}) =>
      repository.getPatientRequests(patientId, status: status);
}
