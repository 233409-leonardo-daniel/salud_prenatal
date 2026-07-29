import '../data/datasources/patients_remote_data_source.dart';
import '../data/datasources/invitation_remote_data_source.dart';
import '../data/datasources/unlink_request_remote_data_source.dart';
import '../data/repositories/patients_repository_impl.dart';
import '../data/repositories/invitation_repository_impl.dart';
import '../data/repositories/unlink_request_repository_impl.dart';
import '../domain/repositories/patients_repository.dart';
import '../domain/repositories/invitation_repository.dart';
import '../domain/repositories/unlink_request_repository.dart';
import '../domain/usecases/get_doctor_patients_usecase.dart';
import '../domain/usecases/get_patient_details_usecase.dart';
import '../domain/usecases/generate_invitation_code_usecase.dart';
import '../domain/usecases/redeem_invitation_code_usecase.dart';
import '../domain/usecases/create_unlink_request_usecase.dart';
import '../domain/usecases/get_patient_unlink_requests_usecase.dart';
import '../domain/usecases/cancel_unlink_request_usecase.dart';
import '../domain/usecases/get_doctor_unlink_requests_usecase.dart';
import '../domain/usecases/resolve_unlink_request_usecase.dart';
import '../../../../core/network/api_client.dart';

/// Compone TODO lo relacionado con la relación paciente-doctor: alta (vía
/// invitación) y baja (vía solicitud de desvinculación aprobada por el
/// doctor). Antes la desvinculación vivía en una feature aparte
/// (`unlink_requests`); se fusionó aquí porque es la misma relación de
/// negocio partida por verbo (vincular/desvincular), no dos conceptos
/// distintos.
class PatientsModule {
  late final PatientsRemoteDataSource remoteDataSource;
  late final PatientsRepository repository;
  late final GetDoctorPatientsUsecase getDoctorPatientsUseCase;
  late final GetPatientDetailsUsecase getPatientDetailsUseCase;
  late final InvitationRemoteDataSource invitationRemoteDataSource;
  late final InvitationRepository invitationRepository;
  late final GenerateInvitationCodeUsecase generateInvitationCodeUseCase;
  late final RedeemInvitationCodeUsecase redeemInvitationCodeUseCase;
  late final UnlinkRequestRemoteDataSource unlinkRequestRemoteDataSource;
  late final UnlinkRequestRepository unlinkRequestRepository;
  late final CreateUnlinkRequestUsecase createUnlinkRequestUseCase;
  late final GetPatientUnlinkRequestsUsecase getPatientUnlinkRequestsUseCase;
  late final CancelUnlinkRequestUsecase cancelUnlinkRequestUseCase;
  late final GetDoctorUnlinkRequestsUsecase getDoctorUnlinkRequestsUseCase;
  late final ResolveUnlinkRequestUsecase resolveUnlinkRequestUseCase;

  PatientsModule(ApiClient apiClient) {
    remoteDataSource = PatientsRemoteDataSourceImpl(apiClient: apiClient);
    repository = PatientsRepositoryImpl(remoteDataSource: remoteDataSource);
    getDoctorPatientsUseCase = GetDoctorPatientsUsecase(repository);
    getPatientDetailsUseCase = GetPatientDetailsUsecase(repository);

    invitationRemoteDataSource = InvitationRemoteDataSourceImpl(apiClient: apiClient);
    invitationRepository = InvitationRepositoryImpl(remoteDataSource: invitationRemoteDataSource);
    generateInvitationCodeUseCase = GenerateInvitationCodeUsecase(invitationRepository);
    redeemInvitationCodeUseCase = RedeemInvitationCodeUsecase(invitationRepository);

    unlinkRequestRemoteDataSource = UnlinkRequestRemoteDataSourceImpl(apiClient: apiClient);
    unlinkRequestRepository = UnlinkRequestRepositoryImpl(remoteDataSource: unlinkRequestRemoteDataSource);
    createUnlinkRequestUseCase = CreateUnlinkRequestUsecase(unlinkRequestRepository);
    getPatientUnlinkRequestsUseCase = GetPatientUnlinkRequestsUsecase(unlinkRequestRepository);
    cancelUnlinkRequestUseCase = CancelUnlinkRequestUsecase(unlinkRequestRepository);
    getDoctorUnlinkRequestsUseCase = GetDoctorUnlinkRequestsUsecase(unlinkRequestRepository);
    resolveUnlinkRequestUseCase = ResolveUnlinkRequestUsecase(unlinkRequestRepository);
  }
}
