import '../data/datasources/register_remote_data_source.dart';
import '../data/repositories/register_repository_impl.dart';
import '../domain/repositories/register_repository.dart';
import '../domain/usecases/register_usecase.dart';
import '../../../../core/network/api_client.dart';

class RegisterModule {
  late final RegisterRepository registerRepository;
  late final RegisterPatientUseCase registerPatientUseCase;
  late final RegisterDoctorUseCase registerDoctorUseCase;

  RegisterModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    registerRepository = RegisterRepositoryImpl(
      remoteDataSource: RegisterRemoteDataSourceImpl(apiClient: apiClient),
    );
    registerPatientUseCase =
        RegisterPatientUseCase(repository: registerRepository);
    registerDoctorUseCase =
        RegisterDoctorUseCase(repository: registerRepository);
  }
}
