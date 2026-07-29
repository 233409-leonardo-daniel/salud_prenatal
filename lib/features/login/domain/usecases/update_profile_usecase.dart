import '../../../profile/domain/entities/user_profile.dart';
import '../repositories/login_repository.dart';

class UpdateProfileUsecase {
  final LoginRepository repository;

  const UpdateProfileUsecase({required this.repository});

  Future<UserProfile> execute(int userId, UserProfile profile, {int? doctorId}) {
    return repository.updateUserProfile(userId, profile, doctorId: doctorId);
  }
}
