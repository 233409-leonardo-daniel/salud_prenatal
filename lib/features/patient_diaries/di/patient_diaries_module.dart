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
  late final GetDiariesByMedicalRecordUseCase getDiariesUseCase;
  late final CreatePatientDiaryUseCase createDiaryUseCase;
  late final UpdatePatientDiaryUseCase updateDiaryUseCase;
  late final DeletePatientDiaryUseCase deleteDiaryUseCase;
  late final GetDiarySymptomsUseCase getDiarySymptomsUseCase;
  late final GetMedicalRecordSymptomHistoryUseCase getSymptomHistoryUseCase;

  PatientDiariesModule(ApiClient apiClient) {
    remoteDataSource = PatientDiaryRemoteDataSourceImpl(apiClient: apiClient);
    repository = PatientDiaryRepositoryImpl(remoteDataSource: remoteDataSource);
    getDiariesUseCase = GetDiariesByMedicalRecordUseCase(repository);
    createDiaryUseCase = CreatePatientDiaryUseCase(repository);
    updateDiaryUseCase = UpdatePatientDiaryUseCase(repository);
    deleteDiaryUseCase = DeletePatientDiaryUseCase(repository);
    getDiarySymptomsUseCase = GetDiarySymptomsUseCase(repository);
    getSymptomHistoryUseCase = GetMedicalRecordSymptomHistoryUseCase(repository);
  }
}
