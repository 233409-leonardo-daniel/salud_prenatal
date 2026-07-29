import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

class CreatePostUsecase {
  final ForumsRepository repository;

  CreatePostUsecase(this.repository);

  Future<ForumPost> call(ForumPost post) {
    return repository.createPost(post);
  }
}
