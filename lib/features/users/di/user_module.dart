import '../data/datasources/user_remote_data_source.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/get_doctors_usecase.dart';
import '../domain/usecases/get_patients_usecase.dart';
import '../domain/usecases/get_user_by_id_usecase.dart';
import '../../../../core/network/api_client.dart';

class UserModule {
  late final UserRemoteDataSource remoteDataSource;
  late final UserRepository repository;
  
  late final GetDoctorsUsecase getDoctorsUseCase;
  late final GetPatientsUsecase getPatientsUseCase;
  late final GetUserByIdUsecase getUserByIdUseCase;

  UserModule(ApiClient apiClient) {
    remoteDataSource = UserRemoteDataSourceImpl(apiClient: apiClient);
    repository = UserRepositoryImpl(remoteDataSource);
    
    getDoctorsUseCase = GetDoctorsUsecase(repository);
    getPatientsUseCase = GetPatientsUsecase(repository);
    getUserByIdUseCase = GetUserByIdUsecase(repository);
  }
}
