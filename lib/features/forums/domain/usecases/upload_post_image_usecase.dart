import 'dart:io';
import '../repositories/forums_repository.dart';

/// Sube una imagen de post/aviso (multipart) y devuelve la URL pública que
/// luego se envía en `image_url` al crear el post.
class UploadPostImageUsecase {
  final ForumsRepository repository;

  UploadPostImageUsecase(this.repository);

  Future<String> call(File file) {
    return repository.uploadPostImage(file);
  }
}
