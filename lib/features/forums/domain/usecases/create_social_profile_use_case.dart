import '../entities/social_profile.dart';
import '../repositories/forums_repository.dart';

class CreateSocialProfileUseCase {
  final ForumsRepository repository;

  CreateSocialProfileUseCase(this.repository);

  Future<SocialProfile> call(SocialProfile profile) {
    return repository.createOrUpdateSocialProfile(profile);
  }
}
