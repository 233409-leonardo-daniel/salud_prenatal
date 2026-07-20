import 'dart:io';
import '../repositories/forums_repository.dart';

/// Sube una foto de perfil (multipart) a /forums/profiles/upload-avatar y
/// devuelve la URL pública, que luego se guarda en el perfil vía
/// PATCH /forums/profiles/me (avatar_url).
class UploadAvatarUseCase {
  final ForumsRepository repository;

  UploadAvatarUseCase(this.repository);

  Future<String> call(File file) {
    return repository.uploadAvatar(file);
  }
}
