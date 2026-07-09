import '../entities/community_group.dart';
import '../repositories/forums_repository.dart';

class CreateGroupUseCase {
  final ForumsRepository repository;

  CreateGroupUseCase(this.repository);

  Future<CommunityGroup> call(CommunityGroup group) {
    return repository.createGroup(group);
  }
}
