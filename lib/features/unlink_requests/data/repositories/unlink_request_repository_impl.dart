import '../../domain/entities/unlink_request.dart';
import '../../domain/repositories/unlink_request_repository.dart';
import '../datasources/unlink_request_remote_data_source.dart';

class UnlinkRequestRepositoryImpl implements UnlinkRequestRepository {
  final UnlinkRequestRemoteDataSource remoteDataSource;

  UnlinkRequestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UnlinkRequestEntity> createRequest(int patientId, String? reason) =>
      remoteDataSource.createRequest(patientId, reason);

  @override
  Future<List<UnlinkRequestEntity>> getPatientRequests(int patientId, {String? status}) =>
      remoteDataSource.getPatientRequests(patientId, status: status);

  @override
  Future<UnlinkRequestEntity> cancelRequest(int patientId, int requestId) =>
      remoteDataSource.cancelRequest(patientId, requestId);

  @override
  Future<List<UnlinkRequestEntity>> getDoctorRequests(int doctorId, {String? status}) =>
      remoteDataSource.getDoctorRequests(doctorId, status: status);

  @override
  Future<UnlinkRequestEntity> resolveRequest(int doctorId, int requestId, String status) =>
      remoteDataSource.resolveRequest(doctorId, requestId, status);
}
