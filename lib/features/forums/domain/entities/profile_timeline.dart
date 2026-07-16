import 'social_profile.dart';
import 'forum_post.dart';

/// Resultado de GET /forums/profiles/{user_id}/timeline: perfil público del
/// usuario junto con TODAS sus publicaciones (incluye posts de grupo y
/// anuncios), paginado por limit/offset.
class ProfileTimeline {
  final SocialProfile profile;
  final List<ForumPost> posts;

  ProfileTimeline({
    required this.profile,
    required this.posts,
  });
}
