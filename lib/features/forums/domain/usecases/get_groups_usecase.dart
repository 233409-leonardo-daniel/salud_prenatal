import '../entities/community_group.dart';
import '../repositories/forums_repository.dart';

class GetGroupsUsecase {
  final ForumsRepository repository;

  GetGroupsUsecase(this.repository);

  Future<List<CommunityGroup>> call() {
    return repository.getGroups();
  }
}
