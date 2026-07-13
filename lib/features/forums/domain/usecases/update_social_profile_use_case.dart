import '../entities/social_profile.dart';
import '../repositories/forums_repository.dart';

/// PATCH /forums/profiles/me: actualización parcial del perfil propio (no
/// existe variante con {user_id}, el backend deriva el usuario del token).
class UpdateSocialProfileUseCase {
  final ForumsRepository repository;

  UpdateSocialProfileUseCase(this.repository);

  Future<SocialProfile> call(SocialProfile profile) {
    return repository.updateSocialProfile(profile);
  }
}
