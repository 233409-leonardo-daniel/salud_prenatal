import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<List<UserEntity>> getDoctors();
  Future<List<UserEntity>> getPatients({int? doctorId});
  Future<UserEntity> getUserById(int id);
}
