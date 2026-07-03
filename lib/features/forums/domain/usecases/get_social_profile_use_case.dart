import '../entities/social_profile.dart';
import '../repositories/forums_repository.dart';

class GetSocialProfileUseCase {
  final ForumsRepository repository;

  GetSocialProfileUseCase(this.repository);

  Future<SocialProfile> call(int userId) {
    return repository.getSocialProfile(userId);
  }
}
