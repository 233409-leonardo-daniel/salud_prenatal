import '../data/datasources/login_remote_data_source.dart';
import '../data/repositories/login_repository_impl.dart';
import '../domain/repositories/login_repository.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/update_profile_usecase.dart';

class LoginModule {
  late final LoginRepository loginRepository;
  late final LoginUseCase loginUseCase;
  late final GetProfileUseCase getProfileUseCase;
  late final UpdateProfileUseCase updateProfileUseCase;

  LoginModule() {
    _initDependencies();
  }

  void _initDependencies() {
    loginRepository = LoginRepositoryImpl(
      remoteDataSource: LoginRemoteDataSourceImpl(),
    );
    loginUseCase = LoginUseCase(repository: loginRepository);
    getProfileUseCase = GetProfileUseCase(repository: loginRepository);
    updateProfileUseCase = UpdateProfileUseCase(repository: loginRepository);
  }
}
