import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetPatientsUsecase {
  final UserRepository repository;

  GetPatientsUsecase(this.repository);

  Future<List<UserEntity>> call({int? doctorId}) async {
    return await repository.getPatients(doctorId: doctorId);
  }
}
