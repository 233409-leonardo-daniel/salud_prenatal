import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

/// Feed "Para ti": posts de autoras del mismo cluster de riesgo, con
/// publicidad de doctores intercalada. Si la usuaria no tiene cluster, el
/// backend cae automáticamente al feed global.
class GetRecommendedFeedUsecase {
  final ForumsRepository repository;

  GetRecommendedFeedUsecase(this.repository);

  Future<List<ForumPost>> call({int limit = 50, int offset = 0}) {
    return repository.getRecommendedFeed(limit, offset);
  }
}
