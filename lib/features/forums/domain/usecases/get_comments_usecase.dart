import '../entities/forum_comment.dart';
import '../repositories/forums_repository.dart';

class GetCommentsUsecase {
  final ForumsRepository repository;

  GetCommentsUsecase(this.repository);

  Future<List<ForumComment>> call(int postId) {
    return repository.getComments(postId);
  }
}
