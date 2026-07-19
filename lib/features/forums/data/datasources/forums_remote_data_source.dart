import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../models/social_profile_model.dart';
import '../models/profile_timeline_model.dart';
import '../models/community_group_model.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/forum_report_model.dart';

/// Se lanza cuando el backend responde 401 en un POST /forums/* (sin token o
/// token expirado). La UI puede detectar este tipo para redirigir a login,
/// en vez de solo mostrar un SnackBar genérico.
class ForumsUnauthorizedException implements Exception {
  final String message;
  ForumsUnauthorizedException([this.message = 'Tu sesión expiró. Vuelve a iniciar sesión.']);

  @override
  String toString() => message;
}

/// Recurso inexistente (HTTP 404). Se usa para distinguir "el perfil aún no
/// existe" y así crearlo en vez de actualizarlo.
class ForumsNotFoundException implements Exception {
  final String message;
  ForumsNotFoundException([this.message = 'Recurso no encontrado.']);

  @override
  String toString() => message;
}

abstract class ForumsRemoteDataSource {
  Future<SocialProfileModel> getSocialProfile(int userId);
  Future<SocialProfileModel> createOrUpdateSocialProfile(SocialProfileModel profile);
  Future<SocialProfileModel> updateSocialProfile(SocialProfileModel profile);
  Future<ProfileTimelineModel> getProfileTimeline(int userId, {int limit = 50, int offset = 0});
  Future<CommunityGroupModel> createGroup(CommunityGroupModel group);
  Future<List<CommunityGroupModel>> getGroups();
  Future<List<CommunityGroupModel>> getRecommendedGroups();
  Future<String> uploadPostImage(File file);
  Future<ForumPostModel> createPost(ForumPostModel post);
  Future<List<ForumPostModel>> getGlobalFeed(int limit, int offset);
  Future<List<ForumPostModel>> getRecommendedFeed(int limit, int offset);
  Future<List<ForumPostModel>> getGroupFeed(int groupId, int limit, int offset);
  Future<ForumCommentModel> createComment(ForumCommentModel comment);
  Future<List<ForumCommentModel>> getComments(int postId);
  Future<void> createReport(ForumReportModel report);
}

class ForumsRemoteDataSourceImpl implements ForumsRemoteDataSource {
  final ApiClient _apiClient;

  ForumsRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Extrae el mensaje de error (`detail`) de una respuesta FastAPI y lanza
  /// la excepción correspondiente. 401 -> ForumsUnauthorizedException (sin
  /// token o token vencido); el resto -> Exception con el detalle real del
  /// backend cuando está disponible (p. ej. "Solo los doctores pueden
  /// publicar publicidad").
  Never _throwError(dynamic response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw ForumsUnauthorizedException();
    }
    try {
      final errorJson = jsonDecode(response.body);
      final detail = errorJson['detail'];
      if (detail is String && detail.isNotEmpty) {
        throw Exception(detail);
      }
    } catch (_) {
      // body no era JSON o no tenía 'detail': usar el mensaje genérico.
    }
    throw Exception('$fallbackMessage (${response.statusCode})');
  }

  @override
  Future<SocialProfileModel> getSocialProfile(int userId) async {
    final response = await _apiClient.get('/forums/profiles/$userId');
    if (response.statusCode == 200) {
      return SocialProfileModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al obtener perfil social');
  }

  @override
  Future<SocialProfileModel> createOrUpdateSocialProfile(SocialProfileModel profile) async {
    final response = await _apiClient.post('/forums/profiles', profile.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SocialProfileModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear o actualizar perfil social');
  }

  @override
  Future<SocialProfileModel> updateSocialProfile(SocialProfileModel profile) async {
    final response = await _apiClient.patch('/forums/profiles/me', profile.toJson());
    if (response.statusCode == 200) {
      return SocialProfileModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al actualizar perfil social');
  }

  @override
  Future<ProfileTimelineModel> getProfileTimeline(int userId, {int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get('/forums/profiles/$userId/timeline?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      return ProfileTimelineModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al obtener la línea de tiempo del perfil');
  }

  @override
  Future<CommunityGroupModel> createGroup(CommunityGroupModel group) async {
    final response = await _apiClient.post('/forums/groups', group.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CommunityGroupModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear grupo');
  }

  @override
  Future<List<CommunityGroupModel>> getGroups() async {
    final response = await _apiClient.get('/forums/groups');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CommunityGroupModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener grupos comunitarios');
  }

  @override
  Future<List<CommunityGroupModel>> getRecommendedGroups() async {
    final response = await _apiClient.get('/forums/groups/recommended');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CommunityGroupModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener grupos recomendados');
  }

  @override
  Future<String> uploadPostImage(File file) async {
    final response = await _apiClient.postMultipartFile(
      '/forums/posts/upload-image',
      file,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final url = data['image_url'];
      if (url is String && url.isNotEmpty) return url;
      throw Exception('El servidor no devolvió la URL de la imagen.');
    }
    _throwError(response, 'Error al subir la imagen');
  }

  @override
  Future<ForumPostModel> createPost(ForumPostModel post) async {
    final response = await _apiClient.post('/forums/posts', post.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumPostModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear publicación');
  }

  @override
  Future<List<ForumPostModel>> getGlobalFeed(int limit, int offset) async {
    final response = await _apiClient.get('/forums/posts/global?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumPostModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener feed global');
  }

  @override
  Future<List<ForumPostModel>> getRecommendedFeed(int limit, int offset) async {
    final response = await _apiClient.get('/forums/posts/recommended?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // El backend ya intercala la publicidad en la posición correcta: se
      // recorre la lista en orden tal cual, sin reordenar ni separar.
      return data.map((e) => ForumPostModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener el feed recomendado');
  }

  @override
  Future<List<ForumPostModel>> getGroupFeed(int groupId, int limit, int offset) async {
    final response = await _apiClient.get('/forums/groups/$groupId/posts?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumPostModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener feed del grupo');
  }

  @override
  Future<ForumCommentModel> createComment(ForumCommentModel comment) async {
    final response = await _apiClient.post('/forums/comments', comment.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumCommentModel.fromJson(jsonDecode(response.body));
    }
    _throwError(response, 'Error al crear comentario');
  }

  @override
  Future<List<ForumCommentModel>> getComments(int postId) async {
    final response = await _apiClient.get('/forums/posts/$postId/comments');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumCommentModel.fromJson(e)).toList();
    }
    _throwError(response, 'Error al obtener comentarios');
  }

  @override
  Future<void> createReport(ForumReportModel report) async {
    final response = await _apiClient.post('/forums/reports', report.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwError(response, 'Error al enviar reporte');
    }
  }
}
