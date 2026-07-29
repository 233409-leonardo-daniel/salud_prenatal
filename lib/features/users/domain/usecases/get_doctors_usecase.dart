import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetDoctorsUsecase {
  final UserRepository repository;

  GetDoctorsUsecase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getDoctors();
  }
}
