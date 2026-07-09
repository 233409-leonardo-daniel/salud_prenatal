import '../repositories/patients_repository.dart';
import '../../../login/domain/entities/user_profile.dart';

class GetPatientDetailsUseCase {
  final PatientsRepository repository;

  GetPatientDetailsUseCase(this.repository);

  Future<UserProfile> call(String userId) async {
    return await repository.getPatientDetails(userId);
  }
}
