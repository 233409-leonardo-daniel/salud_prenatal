import 'dart:io';
import '../repositories/forums_repository.dart';

/// Sube una foto de perfil (multipart) a /forums/profiles/upload-avatar y
/// devuelve la URL pública, que luego se guarda en el perfil vía
/// PATCH /forums/profiles/me (avatar_url).
class UploadAvatarUsecase {
  final ForumsRepository repository;

  UploadAvatarUsecase(this.repository);

  Future<String> call(File file) {
    return repository.uploadAvatar(file);
  }
}
