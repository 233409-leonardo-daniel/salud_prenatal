import '../data/datasources/user_remote_data_source.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/get_doctors_use_case.dart';
import '../domain/usecases/get_patients_use_case.dart';
import '../domain/usecases/get_user_by_id_use_case.dart';

class UserModule {
  late final UserRemoteDataSource remoteDataSource;
  late final UserRepository repository;
  
  late final GetDoctorsUseCase getDoctorsUseCase;
  late final GetPatientsUseCase getPatientsUseCase;
  late final GetUserByIdUseCase getUserByIdUseCase;

  UserModule() {
    remoteDataSource = UserRemoteDataSourceImpl();
    repository = UserRepositoryImpl(remoteDataSource);
    
    getDoctorsUseCase = GetDoctorsUseCase(repository);
    getPatientsUseCase = GetPatientsUseCase(repository);
    getUserByIdUseCase = GetUserByIdUseCase(repository);
  }
}
