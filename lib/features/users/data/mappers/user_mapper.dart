import '../../domain/entities/user_entity.dart';
import '../models/user_dto.dart';

class UserMapper {
  static UserEntity dtoToEntity(UserDto dto) {
    return UserEntity(
      id: dto.id,
      email: dto.email,
      fullName: dto.fullName,
      role: dto.role,
      phoneNumber: dto.phoneNumber,
      profilePicture: dto.profilePicture,
      doctorId: dto.doctorId,
      specialty: dto.specialty,
      professionalLicense: dto.professionalLicense,
      office: dto.office,
    );
  }

  static UserDto entityToDto(UserEntity entity) {
    return UserDto(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      role: entity.role,
      phoneNumber: entity.phoneNumber,
      profilePicture: entity.profilePicture,
      doctorId: entity.doctorId,
      specialty: entity.specialty,
      professionalLicense: entity.professionalLicense,
      office: entity.office,
    );
  }
}
