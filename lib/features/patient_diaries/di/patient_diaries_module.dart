import '../data/datasources/patient_diary_remote_data_source.dart';
import '../data/repositories/patient_diary_repository_impl.dart';
import '../domain/repositories/patient_diary_repository.dart';
import '../domain/usecases/create_patient_diary_usecase.dart';
import '../domain/usecases/delete_patient_diary_usecase.dart';
import '../domain/usecases/get_patient_diaries_usecase.dart';
import '../domain/usecases/update_patient_diary_usecase.dart';
import '../domain/usecases/get_diary_symptoms_usecase.dart';
import '../domain/usecases/get_medical_record_symptom_history_usecase.dart';
import '../../../../core/network/api_client.dart';

class PatientDiariesModule {
  late final PatientDiaryRemoteDataSource remoteDataSource;
  late final PatientDiaryRepository repository;
  late final GetDiariesByMedicalRecordUsecase getDiariesUseCase;
  late final CreatePatientDiaryUsecase createDiaryUseCase;
  late final UpdatePatientDiaryUsecase updateDiaryUseCase;
  late final DeletePatientDiaryUsecase deleteDiaryUseCase;
  late final GetDiarySymptomsUsecase getDiarySymptomsUseCase;
  late final GetMedicalRecordSymptomHistoryUsecase getSymptomHistoryUseCase;

  PatientDiariesModule(ApiClient apiClient) {
    remoteDataSource = PatientDiaryRemoteDataSourceImpl(apiClient: apiClient);
    repository = PatientDiaryRepositoryImpl(remoteDataSource: remoteDataSource);
    getDiariesUseCase = GetDiariesByMedicalRecordUsecase(repository);
    createDiaryUseCase = CreatePatientDiaryUsecase(repository);
    updateDiaryUseCase = UpdatePatientDiaryUsecase(repository);
    deleteDiaryUseCase = DeletePatientDiaryUsecase(repository);
    getDiarySymptomsUseCase = GetDiarySymptomsUsecase(repository);
    getSymptomHistoryUseCase = GetMedicalRecordSymptomHistoryUsecase(repository);
  }
}
