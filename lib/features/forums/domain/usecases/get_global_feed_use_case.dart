import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

class GetGlobalFeedUseCase {
  final ForumsRepository repository;

  GetGlobalFeedUseCase(this.repository);

  Future<List<ForumPost>> call({int limit = 50, int offset = 0}) {
    return repository.getGlobalFeed(limit, offset);
  }
}
