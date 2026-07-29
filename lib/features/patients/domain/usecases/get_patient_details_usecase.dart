import '../repositories/patients_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';

class GetPatientDetailsUsecase {
  final PatientsRepository repository;

  GetPatientDetailsUsecase(this.repository);

  Future<UserProfile> call(String userId) async {
    return await repository.getPatientDetails(userId);
  }
}
