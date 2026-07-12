import '../entities/user_profile.dart';
import '../repositories/login_repository.dart';

class UpdateProfileUseCase {
  final LoginRepository repository;

  const UpdateProfileUseCase({required this.repository});

  Future<UserProfile> execute(int userId, UserProfile profile, {int? doctorId}) {
    return repository.updateUserProfile(userId, profile, doctorId: doctorId);
  }
}
