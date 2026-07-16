import '../entities/profile_timeline.dart';
import '../repositories/forums_repository.dart';

/// GET /forums/profiles/{user_id}/timeline: perfil público + TODAS sus
/// publicaciones (incluye posts de grupo y anuncios), paginado.
class GetProfileTimelineUseCase {
  final ForumsRepository repository;

  GetProfileTimelineUseCase(this.repository);

  Future<ProfileTimeline> call(int userId, {int limit = 50, int offset = 0}) {
    return repository.getProfileTimeline(userId, limit: limit, offset: offset);
  }
}
