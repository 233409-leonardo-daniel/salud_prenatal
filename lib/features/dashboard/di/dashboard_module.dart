import '../data/datasources/dashboard_remote_data_source.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/usecases/get_all_users_usecase.dart';
import '../domain/usecases/get_patients_by_doctor_usecase.dart';
import '../domain/usecases/get_medical_record_by_patient_usecase.dart';
import '../domain/usecases/get_consultations_by_medical_record_usecase.dart';
import '../domain/usecases/get_consultations_from_patient_endpoint_usecase.dart';
import '../domain/usecases/get_patient_dashboard_usecase.dart';
import '../domain/usecases/create_medical_record_usecase.dart';
import '../domain/usecases/update_medical_record_usecase.dart';
import '../domain/usecases/evaluate_risk_usecase.dart';
import '../domain/usecases/get_doctor_dashboard_usecase.dart';
import '../domain/usecases/get_receptionist_dashboard_usecase.dart';
import '../domain/usecases/create_consultation_usecase.dart';
import '../../../../core/network/api_client.dart';

class DashboardModule {
  late final DashboardRemoteDataSource remoteDataSource;
  late final DashboardRepository repository;
  late final GetAllUsersUsecase getAllUsersUseCase;
  late final GetPatientsByDoctorUsecase getPatientsByDoctorUseCase;
  late final GetMedicalRecordByPatientUsecase getMedicalRecordByPatientUseCase;
  late final GetConsultationsByMedicalRecordUsecase getConsultationsByMedicalRecordUseCase;
  late final GetConsultationsFromPatientEndpointUsecase getConsultationsFromPatientEndpointUseCase;
  late final GetPatientDashboardUsecase getPatientDashboardUseCase;
  late final GetDoctorDashboardUsecase getDoctorDashboardUseCase;
  late final GetReceptionistDashboardUsecase getReceptionistDashboardUseCase;
  late final CreateMedicalRecordUsecase createMedicalRecordUseCase;
  late final UpdateMedicalRecordUsecase updateMedicalRecordUseCase;
  late final EvaluateRiskUsecase evaluateRiskUseCase;
  late final CreateConsultationUsecase createConsultationUseCase;

  DashboardModule(ApiClient apiClient) {
    remoteDataSource = DashboardRemoteDataSourceImpl(apiClient: apiClient);
    repository = DashboardRepositoryImpl(remoteDataSource: remoteDataSource);

    getAllUsersUseCase = GetAllUsersUsecase(repository);
    getPatientsByDoctorUseCase = GetPatientsByDoctorUsecase(repository);
    getMedicalRecordByPatientUseCase = GetMedicalRecordByPatientUsecase(repository);
    getConsultationsByMedicalRecordUseCase = GetConsultationsByMedicalRecordUsecase(repository);
    getConsultationsFromPatientEndpointUseCase = GetConsultationsFromPatientEndpointUsecase(repository);
    getPatientDashboardUseCase = GetPatientDashboardUsecase(repository);
    getDoctorDashboardUseCase = GetDoctorDashboardUsecase(repository);
    getReceptionistDashboardUseCase = GetReceptionistDashboardUsecase(repository);
    createMedicalRecordUseCase = CreateMedicalRecordUsecase(repository);
    updateMedicalRecordUseCase = UpdateMedicalRecordUsecase(repository);
    evaluateRiskUseCase = EvaluateRiskUsecase(repository);
    createConsultationUseCase = CreateConsultationUsecase(repository);
  }
}
