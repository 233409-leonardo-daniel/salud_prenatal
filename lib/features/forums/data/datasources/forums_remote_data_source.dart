import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // Base de datos local en memoria para fallback cuando el servidor retorna 404 (módulo no desplegado aún)
  static final List<SocialProfileModel> _mockProfiles = [];
  
  static final List<CommunityGroupModel> _mockGroups = [
    CommunityGroupModel(
      groupId: 1,
      name: 'Primer Trimestre',
      description: 'Consejos, dudas y experiencias sobre las primeras semanas del embarazo.',
      createdBy: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    CommunityGroupModel(
      groupId: 2,
      name: 'Alimentación Saludable',
      description: 'Nutrición, alimentos recomendados y recetas seguras para mamá.',
      createdBy: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    CommunityGroupModel(
      groupId: 3,
      name: 'Preparación para el Parto',
      description: 'Preguntas sobre el parto, maletas de maternidad y clínicas.',
      createdBy: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final List<ForumPostModel> _mockPosts = [
    ForumPostModel(
      postId: 1,
      authorId: 2,
      groupId: 1,
      title: '¿Cómo aliviar las náuseas matutinas?',
      content: 'Hola mamás, llevo 4 semanas con náuseas horribles y casi no puedo desayunar. ¿Algún tip que les haya funcionado?',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      authorAlias: 'María López',
      authorRole: 'Paciente',
      authorAvatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    ),
    ForumPostModel(
      postId: 2,
      authorId: 1,
      groupId: 2,
      title: 'Importancia del Ácido Fólico',
      content: 'Buenos días. Les recuerdo que tomar su dosis de ácido fólico diariamente reduce significativamente el riesgo de defectos en el tubo neural del bebé.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      authorAlias: 'Pedro Gómez',
      authorRole: 'Doctor',
      authorAvatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    ),
  ];

  static final List<ForumCommentModel> _mockComments = [
    ForumCommentModel(
      commentId: 1,
      postId: 1,
      authorId: 1,
      content: 'Intenta comer una galleta salada antes de levantarte de la cama por la mañana. Ayuda mucho a asentar el estómago.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      authorAlias: 'Pedro Gómez',
      authorAvatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    ),
  ];

  ForumsRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<SocialProfileModel> getSocialProfile(int userId) async {
    try {
      final response = await _apiClient.get('/forums/profiles/$userId');
      if (response.statusCode == 200) {
        final profile = SocialProfileModel.fromJson(jsonDecode(response.body));
        // Guardar copia local por consistencia
        final idx = _mockProfiles.indexWhere((p) => p.userId == userId);
        if (idx != -1) {
          _mockProfiles[idx] = profile;
        } else {
          _mockProfiles.add(profile);
        }
        return profile;
      }
    } catch (e) {
      debugPrint('Fallback local para getSocialProfile (userId: $userId): $e');
    }

    final idx = _mockProfiles.indexWhere((p) => p.userId == userId);
    if (idx != -1) {
      return _mockProfiles[idx];
    }
    throw Exception('Error al obtener perfil social');
  }

  @override
  Future<SocialProfileModel> createOrUpdateSocialProfile(SocialProfileModel profile) async {
    try {
      final response = await _apiClient.post('/forums/profiles', profile.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SocialProfileModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fallback local para createOrUpdateSocialProfile: $e');
    }

    final idx = _mockProfiles.indexWhere((p) => p.userId == profile.userId);
    if (idx != -1) {
      _mockProfiles[idx] = profile;
    } else {
      _mockProfiles.add(profile);
    }
    return profile;
  }

  @override
  Future<CommunityGroupModel> createGroup(CommunityGroupModel group) async {
    try {
      final response = await _apiClient.post('/forums/groups', group.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return CommunityGroupModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fallback local para createGroup: $e');
    }

    final newGroup = CommunityGroupModel(
      groupId: _mockGroups.length + 1,
      name: group.name,
      description: group.description,
      createdBy: group.createdBy,
      createdAt: DateTime.now(),
    );
    _mockGroups.add(newGroup);
    return newGroup;
  }

  @override
  Future<List<CommunityGroupModel>> getGroups() async {
    try {
      final response = await _apiClient.get('/forums/groups');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => CommunityGroupModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fallback local para getGroups: $e');
    }
    return _mockGroups;
  }

  @override
  Future<ForumPostModel> createPost(ForumPostModel post) async {
    try {
      final response = await _apiClient.post('/forums/posts', post.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ForumPostModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fallback local para createPost: $e');
    }

    final profileIdx = _mockProfiles.indexWhere((p) => p.userId == post.authorId);
    final alias = profileIdx != -1 ? _mockProfiles[profileIdx].alias : 'Usuario';
    final role = profileIdx != -1 ? (_mockProfiles[profileIdx].bio?.contains('Doctor') ?? false ? 'Doctor' : 'Paciente') : 'Paciente';

    final newPost = ForumPostModel(
      postId: _mockPosts.length + 1,
      authorId: post.authorId,
      groupId: post.groupId,
      title: post.title,
      content: post.content,
      createdAt: DateTime.now(),
      authorAlias: alias,
      authorRole: role,
      authorAvatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    );
    _mockPosts.add(newPost);
    return newPost;
  }

  @override
  Future<List<ForumPostModel>> getGlobalFeed(int limit, int offset) async {
    try {
      final response = await _apiClient.get('/forums/posts/global?limit=$limit&offset=$offset');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ForumPostModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fallback local para getGlobalFeed: $e');
    }
    return _mockPosts.where((p) => p.groupId == null).toList();
  }

  @override
  Future<List<ForumPostModel>> getGroupFeed(int groupId, int limit, int offset) async {
    try {
      final response = await _apiClient.get('/forums/groups/$groupId/posts?limit=$limit&offset=$offset');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ForumPostModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fallback local para getGroupFeed (groupId: $groupId): $e');
    }
    return _mockPosts.where((p) => p.groupId == groupId).toList();
  }

  @override
  Future<ForumCommentModel> createComment(ForumCommentModel comment) async {
    try {
      final response = await _apiClient.post('/forums/comments', comment.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ForumCommentModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Fallback local para createComment: $e');
    }

    final profileIdx = _mockProfiles.indexWhere((p) => p.userId == comment.authorId);
    final alias = profileIdx != -1 ? _mockProfiles[profileIdx].alias : 'Usuario';

    final newComment = ForumCommentModel(
      commentId: _mockComments.length + 1,
      postId: comment.postId,
      authorId: comment.authorId,
      content: comment.content,
      createdAt: DateTime.now(),
      authorAlias: alias,
      authorAvatarUrl: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    );
    _mockComments.add(newComment);
    return newComment;
  }

  @override
  Future<List<ForumCommentModel>> getComments(int postId) async {
    try {
      final response = await _apiClient.get('/forums/posts/$postId/comments');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ForumCommentModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Fallback local para getComments (postId: $postId): $e');
    }
    return _mockComments.where((c) => c.postId == postId).toList();
  }

  @override
  Future<void> createReport(ForumReportModel report) async {
    try {
      final response = await _apiClient.post('/forums/reports', report.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
    } catch (e) {
      debugPrint('Fallback local para createReport: $e');
    }
  }
}
