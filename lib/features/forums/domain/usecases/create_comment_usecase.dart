import '../entities/forum_comment.dart';
import '../repositories/forums_repository.dart';

class CreateCommentUsecase {
  final ForumsRepository repository;

  CreateCommentUsecase(this.repository);

  Future<ForumComment> call(ForumComment comment) {
    return repository.createComment(comment);
  }
}
