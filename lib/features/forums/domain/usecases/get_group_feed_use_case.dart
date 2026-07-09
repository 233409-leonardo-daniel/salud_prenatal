import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

class GetGroupFeedUseCase {
  final ForumsRepository repository;

  GetGroupFeedUseCase(this.repository);

  Future<List<ForumPost>> call(int groupId, {int limit = 50, int offset = 0}) {
    return repository.getGroupFeed(groupId, limit, offset);
  }
}
