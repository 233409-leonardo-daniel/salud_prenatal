import '../../../../core/network/api_client.dart';
import '../data/datasources/unlink_request_remote_data_source.dart';
import '../data/repositories/unlink_request_repository_impl.dart';
import '../domain/repositories/unlink_request_repository.dart';
import '../domain/usecases/create_unlink_request_usecase.dart';
import '../domain/usecases/get_patient_unlink_requests_usecase.dart';
import '../domain/usecases/cancel_unlink_request_usecase.dart';
import '../domain/usecases/get_doctor_unlink_requests_usecase.dart';
import '../domain/usecases/resolve_unlink_request_usecase.dart';

class UnlinkRequestsModule {
  late final UnlinkRequestRemoteDataSource remoteDataSource;
  late final UnlinkRequestRepository repository;
  late final CreateUnlinkRequestUseCase createUnlinkRequestUseCase;
  late final GetPatientUnlinkRequestsUseCase getPatientUnlinkRequestsUseCase;
  late final CancelUnlinkRequestUseCase cancelUnlinkRequestUseCase;
  late final GetDoctorUnlinkRequestsUseCase getDoctorUnlinkRequestsUseCase;
  late final ResolveUnlinkRequestUseCase resolveUnlinkRequestUseCase;

  UnlinkRequestsModule(ApiClient apiClient) {
    remoteDataSource = UnlinkRequestRemoteDataSourceImpl(apiClient: apiClient);
    repository = UnlinkRequestRepositoryImpl(remoteDataSource: remoteDataSource);
    createUnlinkRequestUseCase = CreateUnlinkRequestUseCase(repository);
    getPatientUnlinkRequestsUseCase = GetPatientUnlinkRequestsUseCase(repository);
    cancelUnlinkRequestUseCase = CancelUnlinkRequestUseCase(repository);
    getDoctorUnlinkRequestsUseCase = GetDoctorUnlinkRequestsUseCase(repository);
    resolveUnlinkRequestUseCase = ResolveUnlinkRequestUseCase(repository);
  }
}
