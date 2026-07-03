import '../entities/forum_post.dart';
import '../repositories/forums_repository.dart';

class CreatePostUseCase {
  final ForumsRepository repository;

  CreatePostUseCase(this.repository);

  Future<ForumPost> call(ForumPost post) {
    return repository.createPost(post);
  }
}
