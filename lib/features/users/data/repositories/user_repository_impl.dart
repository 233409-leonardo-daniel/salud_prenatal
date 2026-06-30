import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../mappers/user_mapper.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<UserEntity>> getDoctors() async {
    final dtos = await _remoteDataSource.getDoctors();
    return dtos.map((dto) => UserMapper.dtoToEntity(dto)).toList();
  }

  @override
  Future<List<UserEntity>> getPatients({int? doctorId}) async {
    final dtos = await _remoteDataSource.getPatients(doctorId: doctorId);
    return dtos.map((dto) => UserMapper.dtoToEntity(dto)).toList();
  }

  @override
  Future<UserEntity> getUserById(int id) async {
    final dto = await _remoteDataSource.getUserById(id);
    return UserMapper.dtoToEntity(dto);
  }
}
