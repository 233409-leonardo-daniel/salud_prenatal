import '../entities/social_profile.dart';
import '../repositories/forums_repository.dart';

class GetSocialProfileUsecase {
  final ForumsRepository repository;

  GetSocialProfileUsecase(this.repository);

  Future<SocialProfile> call(int userId) {
    return repository.getSocialProfile(userId);
  }
}
