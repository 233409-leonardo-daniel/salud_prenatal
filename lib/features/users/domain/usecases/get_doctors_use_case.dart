import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetDoctorsUseCase {
  final UserRepository repository;

  GetDoctorsUseCase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getDoctors();
  }
}
