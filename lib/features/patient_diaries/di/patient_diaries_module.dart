import '../data/datasources/patient_diary_remote_data_source.dart';
import '../data/repositories/patient_diary_repository_impl.dart';
import '../domain/repositories/patient_diary_repository.dart';
import '../domain/usecases/create_patient_diary_usecase.dart';
import '../domain/usecases/delete_patient_diary_usecase.dart';
import '../domain/usecases/get_patient_diaries_usecase.dart';
import '../domain/usecases/update_patient_diary_usecase.dart';

class PatientDiariesModule {
  late final PatientDiaryRemoteDataSource remoteDataSource;
  late final PatientDiaryRepository repository;
  late final GetDiariesByMedicalRecordUseCase getDiariesUseCase;
  late final CreatePatientDiaryUseCase createDiaryUseCase;
  late final UpdatePatientDiaryUseCase updateDiaryUseCase;
  late final DeletePatientDiaryUseCase deleteDiaryUseCase;

  PatientDiariesModule() {
    remoteDataSource = PatientDiaryRemoteDataSourceImpl();
    repository = PatientDiaryRepositoryImpl(remoteDataSource: remoteDataSource);
    getDiariesUseCase = GetDiariesByMedicalRecordUseCase(repository);
    createDiaryUseCase = CreatePatientDiaryUseCase(repository);
    updateDiaryUseCase = UpdatePatientDiaryUseCase(repository);
    deleteDiaryUseCase = DeletePatientDiaryUseCase(repository);
  }
}
