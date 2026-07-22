import '../entities/unlink_request.dart';

abstract class UnlinkRequestRepository {
  Future<UnlinkRequestEntity> createRequest(int patientId, String? reason);
  Future<List<UnlinkRequestEntity>> getPatientRequests(int patientId, {String? status});
  Future<UnlinkRequestEntity> cancelRequest(int patientId, int requestId);
  Future<List<UnlinkRequestEntity>> getDoctorRequests(int doctorId, {String? status});
  Future<UnlinkRequestEntity> resolveRequest(int doctorId, int requestId, String status);
}
