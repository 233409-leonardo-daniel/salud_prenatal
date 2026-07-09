import '../entities/forum_comment.dart';
import '../repositories/forums_repository.dart';

class CreateCommentUseCase {
  final ForumsRepository repository;

  CreateCommentUseCase(this.repository);

  Future<ForumComment> call(ForumComment comment) {
    return repository.createComment(comment);
  }
}
