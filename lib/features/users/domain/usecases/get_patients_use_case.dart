import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetPatientsUseCase {
  final UserRepository repository;

  GetPatientsUseCase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getPatients();
  }
}
