import '../entities/forum_comment.dart';
import '../repositories/forums_repository.dart';

class GetCommentsUseCase {
  final ForumsRepository repository;

  GetCommentsUseCase(this.repository);

  Future<List<ForumComment>> call(int postId) {
    return repository.getComments(postId);
  }
}
