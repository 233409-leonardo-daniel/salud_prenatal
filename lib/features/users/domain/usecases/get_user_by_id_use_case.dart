import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  Future<UserEntity> call(int id) async {
    return await repository.getUserById(id);
  }
}
