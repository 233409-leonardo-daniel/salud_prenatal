import '../entities/community_group.dart';
import '../repositories/forums_repository.dart';

class GetGroupsUseCase {
  final ForumsRepository repository;

  GetGroupsUseCase(this.repository);

  Future<List<CommunityGroup>> call() {
    return repository.getGroups();
  }
}
