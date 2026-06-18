import '../data/datasources/register_remote_data_source.dart';
import '../data/repositories/register_repository_impl.dart';
import '../domain/repositories/register_repository.dart';
import '../domain/usecases/register_usecase.dart';

class RegisterModule {
  late final RegisterRepository registerRepository;
  late final RegisterPatientUseCase registerPatientUseCase;
  late final RegisterDoctorUseCase registerDoctorUseCase;

  RegisterModule() {
    _initDependencies();
  }

  void _initDependencies() {
    registerRepository = RegisterRepositoryImpl(
      remoteDataSource: RegisterRemoteDataSourceImpl(),
    );
    registerPatientUseCase =
        RegisterPatientUseCase(repository: registerRepository);
    registerDoctorUseCase =
        RegisterDoctorUseCase(repository: registerRepository);
  }
}
