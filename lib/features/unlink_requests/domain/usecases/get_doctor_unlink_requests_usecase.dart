import '../entities/unlink_request.dart';
import '../repositories/unlink_request_repository.dart';

class GetDoctorUnlinkRequestsUseCase {
  final UnlinkRequestRepository repository;
  GetDoctorUnlinkRequestsUseCase(this.repository);

  Future<List<UnlinkRequestEntity>> call(int doctorId, {String? status}) =>
      repository.getDoctorRequests(doctorId, status: status);
}
