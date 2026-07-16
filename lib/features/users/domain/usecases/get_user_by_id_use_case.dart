import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCase(this.repository);

  /// [doctorId]: si se conoce (p. ej. es el usuario actual), evita el escaneo
  /// secuencial de `/doctors/1..50` al resolver los datos del doctor.
  Future<UserEntity> call(int id, {int? doctorId}) async {
    return await repository.getUserById(id, doctorId: doctorId);
  }
}
