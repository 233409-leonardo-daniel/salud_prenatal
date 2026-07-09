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
import '../domain/usecases/evaluate_risk_usecase.dart';
import '../domain/usecases/get_doctor_dashboard_usecase.dart';
import '../domain/usecases/get_receptionist_dashboard_usecase.dart';
import '../../../../core/network/api_client.dart';

class DashboardModule {
  late final DashboardRemoteDataSource remoteDataSource;
  late final DashboardRepository repository;
  late final GetAllUsersUseCase getAllUsersUseCase;
  late final GetPatientsByDoctorUseCase getPatientsByDoctorUseCase;
  late final GetMedicalRecordByPatientUseCase getMedicalRecordByPatientUseCase;
  late final GetConsultationsByMedicalRecordUseCase getConsultationsByMedicalRecordUseCase;
  late final GetConsultationsFromPatientEndpointUseCase getConsultationsFromPatientEndpointUseCase;
  late final GetPatientDashboardUseCase getPatientDashboardUseCase;
  late final GetDoctorDashboardUseCase getDoctorDashboardUseCase;
  late final GetReceptionistDashboardUseCase getReceptionistDashboardUseCase;
  late final CreateMedicalRecordUseCase createMedicalRecordUseCase;
  late final EvaluateRiskUseCase evaluateRiskUseCase;

  DashboardModule(ApiClient apiClient) {
    remoteDataSource = DashboardRemoteDataSourceImpl(apiClient: apiClient);
    repository = DashboardRepositoryImpl(remoteDataSource: remoteDataSource);

    getAllUsersUseCase = GetAllUsersUseCase(repository);
    getPatientsByDoctorUseCase = GetPatientsByDoctorUseCase(repository);
    getMedicalRecordByPatientUseCase = GetMedicalRecordByPatientUseCase(repository);
    getConsultationsByMedicalRecordUseCase = GetConsultationsByMedicalRecordUseCase(repository);
    getConsultationsFromPatientEndpointUseCase = GetConsultationsFromPatientEndpointUseCase(repository);
    getPatientDashboardUseCase = GetPatientDashboardUseCase(repository);
    getDoctorDashboardUseCase = GetDoctorDashboardUseCase(repository);
    getReceptionistDashboardUseCase = GetReceptionistDashboardUseCase(repository);
    createMedicalRecordUseCase = CreateMedicalRecordUseCase(repository);
    evaluateRiskUseCase = EvaluateRiskUseCase(repository);
  }
}
