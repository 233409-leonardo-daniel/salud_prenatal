import '../entities/community_group.dart';
import '../repositories/forums_repository.dart';

class CreateGroupUsecase {
  final ForumsRepository repository;

  CreateGroupUsecase(this.repository);

  Future<CommunityGroup> call(CommunityGroup group) {
    return repository.createGroup(group);
  }
}
