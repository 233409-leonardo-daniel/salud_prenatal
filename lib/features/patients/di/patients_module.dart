import '../data/datasources/patients_remote_data_source.dart';
import '../data/datasources/invitation_remote_data_source.dart';
import '../data/repositories/patients_repository_impl.dart';
import '../data/repositories/invitation_repository_impl.dart';
import '../domain/repositories/patients_repository.dart';
import '../domain/repositories/invitation_repository.dart';
import '../domain/usecases/get_doctor_patients_usecase.dart';
import '../domain/usecases/get_patient_details_usecase.dart';
import '../domain/usecases/unlink_patient_usecase.dart';
import '../domain/usecases/generate_invitation_code_usecase.dart';
import '../domain/usecases/redeem_invitation_code_usecase.dart';
import '../../../../core/network/api_client.dart';

class PatientsModule {
  late final PatientsRemoteDataSource remoteDataSource;
  late final PatientsRepository repository;
  late final GetDoctorPatientsUseCase getDoctorPatientsUseCase;
  late final GetPatientDetailsUseCase getPatientDetailsUseCase;
  late final UnlinkPatientUseCase unlinkPatientUseCase;
  late final InvitationRemoteDataSource invitationRemoteDataSource;
  late final InvitationRepository invitationRepository;
  late final GenerateInvitationCodeUseCase generateInvitationCodeUseCase;
  late final RedeemInvitationCodeUseCase redeemInvitationCodeUseCase;

  PatientsModule(ApiClient apiClient) {
    remoteDataSource = PatientsRemoteDataSourceImpl(apiClient: apiClient);
    repository = PatientsRepositoryImpl(remoteDataSource: remoteDataSource);
    getDoctorPatientsUseCase = GetDoctorPatientsUseCase(repository);
    getPatientDetailsUseCase = GetPatientDetailsUseCase(repository);
    unlinkPatientUseCase = UnlinkPatientUseCase(repository);

    invitationRemoteDataSource = InvitationRemoteDataSourceImpl(apiClient: apiClient);
    invitationRepository = InvitationRepositoryImpl(remoteDataSource: invitationRemoteDataSource);
    generateInvitationCodeUseCase = GenerateInvitationCodeUseCase(invitationRepository);
    redeemInvitationCodeUseCase = RedeemInvitationCodeUseCase(invitationRepository);
  }
}
