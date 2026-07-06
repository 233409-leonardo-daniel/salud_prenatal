import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../models/social_profile_model.dart';
import '../models/community_group_model.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/forum_report_model.dart';

abstract class ForumsRemoteDataSource {
  Future<SocialProfileModel> getSocialProfile(int userId);
  Future<SocialProfileModel> createOrUpdateSocialProfile(SocialProfileModel profile);
  Future<CommunityGroupModel> createGroup(CommunityGroupModel group);
  Future<List<CommunityGroupModel>> getGroups();
  Future<ForumPostModel> createPost(ForumPostModel post);
  Future<List<ForumPostModel>> getGlobalFeed(int limit, int offset);
  Future<List<ForumPostModel>> getGroupFeed(int groupId, int limit, int offset);
  Future<ForumCommentModel> createComment(ForumCommentModel comment);
  Future<List<ForumCommentModel>> getComments(int postId);
  Future<void> createReport(ForumReportModel report);
}

class ForumsRemoteDataSourceImpl implements ForumsRemoteDataSource {
  final ApiClient _apiClient;

  ForumsRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<SocialProfileModel> getSocialProfile(int userId) async {
    final response = await _apiClient.get('/forums/profiles/$userId');
    if (response.statusCode == 200) {
      return SocialProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener perfil social (${response.statusCode})');
  }

  @override
  Future<SocialProfileModel> createOrUpdateSocialProfile(SocialProfileModel profile) async {
    final response = await _apiClient.post('/forums/profiles', profile.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return SocialProfileModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear o actualizar perfil social (${response.statusCode})');
  }

  @override
  Future<CommunityGroupModel> createGroup(CommunityGroupModel group) async {
    final response = await _apiClient.post('/forums/groups', group.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return CommunityGroupModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear grupo (${response.statusCode})');
  }

  @override
  Future<List<CommunityGroupModel>> getGroups() async {
    final response = await _apiClient.get('/forums/groups');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CommunityGroupModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener grupos comunitarios (${response.statusCode})');
  }

  @override
  Future<ForumPostModel> createPost(ForumPostModel post) async {
    final response = await _apiClient.post('/forums/posts', post.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumPostModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear publicación (${response.statusCode})');
  }

  @override
  Future<List<ForumPostModel>> getGlobalFeed(int limit, int offset) async {
    final response = await _apiClient.get('/forums/posts/global?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumPostModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener feed global (${response.statusCode})');
  }

  @override
  Future<List<ForumPostModel>> getGroupFeed(int groupId, int limit, int offset) async {
    final response = await _apiClient.get('/forums/groups/$groupId/posts?limit=$limit&offset=$offset');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumPostModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener feed del grupo (${response.statusCode})');
  }

  @override
  Future<ForumCommentModel> createComment(ForumCommentModel comment) async {
    final response = await _apiClient.post('/forums/comments', comment.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumCommentModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear comentario (${response.statusCode})');
  }

  @override
  Future<List<ForumCommentModel>> getComments(int postId) async {
    final response = await _apiClient.get('/forums/posts/$postId/comments');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ForumCommentModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener comentarios (${response.statusCode})');
  }

  @override
  Future<void> createReport(ForumReportModel report) async {
    final response = await _apiClient.post('/forums/reports', report.toJson());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al enviar reporte (${response.statusCode})');
    }
  }
}
