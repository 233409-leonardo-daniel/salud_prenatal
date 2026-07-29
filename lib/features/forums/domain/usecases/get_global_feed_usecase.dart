import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

class GetGlobalFeedUsecase {
  final ForumsRepository repository;

  GetGlobalFeedUsecase(this.repository);

  Future<List<ForumPost>> call({int limit = 50, int offset = 0}) {
    return repository.getGlobalFeed(limit, offset);
  }
}
