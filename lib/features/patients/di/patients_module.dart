import '../data/datasources/patients_remote_data_source.dart';
import '../data/datasources/invitation_remote_data_source.dart';
import '../data/repositories/patients_repository_impl.dart';
import '../domain/repositories/patients_repository.dart';
import '../domain/usecases/get_doctor_patients_usecase.dart';
import '../domain/usecases/get_patient_details_usecase.dart';
import '../../../../core/network/api_client.dart';

class PatientsModule {
  late final PatientsRemoteDataSource remoteDataSource;
  late final PatientsRepository repository;
  late final GetDoctorPatientsUseCase getDoctorPatientsUseCase;
  late final GetPatientDetailsUseCase getPatientDetailsUseCase;
  late final InvitationRemoteDataSource invitationRemoteDataSource;

  PatientsModule(ApiClient apiClient) {
    remoteDataSource = PatientsRemoteDataSourceImpl(apiClient: apiClient);
    repository = PatientsRepositoryImpl(remoteDataSource: remoteDataSource);
    getDoctorPatientsUseCase = GetDoctorPatientsUseCase(repository);
    getPatientDetailsUseCase = GetPatientDetailsUseCase(repository);
    invitationRemoteDataSource = InvitationRemoteDataSourceImpl(apiClient: apiClient);
  }
}
