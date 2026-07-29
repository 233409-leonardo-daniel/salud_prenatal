import '../entities/social_profile.dart';
import '../repositories/forums_repository.dart';

class CreateSocialProfileUsecase {
  final ForumsRepository repository;

  CreateSocialProfileUsecase(this.repository);

  Future<SocialProfile> call(SocialProfile profile) {
    return repository.createOrUpdateSocialProfile(profile);
  }
}
