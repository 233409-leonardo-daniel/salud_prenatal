import 'package:flutter/material.dart';
import '../../domain/entities/social_profile.dart';
import '../../domain/entities/community_group.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_comment.dart';
import '../../domain/entities/forum_report.dart';
import '../../domain/usecases/get_social_profile_use_case.dart';
import '../../domain/usecases/create_social_profile_use_case.dart';
import '../../domain/usecases/create_group_use_case.dart';
import '../../domain/usecases/get_groups_use_case.dart';
import '../../domain/usecases/create_post_use_case.dart';
import '../../domain/usecases/get_global_feed_use_case.dart';
import '../../domain/usecases/get_group_feed_use_case.dart';
import '../../domain/usecases/create_comment_use_case.dart';
import '../../domain/usecases/get_comments_use_case.dart';
import '../../domain/usecases/create_report_use_case.dart';
import '../pages/forums_state.dart';

class ForumsProvider with ChangeNotifier {
  final GetSocialProfileUseCase _getSocialProfileUseCase;
  final CreateSocialProfileUseCase _createSocialProfileUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final GetGroupsUseCase _getGroupsUseCase;
  final CreatePostUseCase _createPostUseCase;
  final GetGlobalFeedUseCase _getGlobalFeedUseCase;
  final GetGroupFeedUseCase _getGroupFeedUseCase;
  final CreateCommentUseCase _createCommentUseCase;
  final GetCommentsUseCase _getCommentsUseCase;
  final CreateReportUseCase _createReportUseCase;

  ForumsProvider({
    required GetSocialProfileUseCase getSocialProfileUseCase,
    required CreateSocialProfileUseCase createSocialProfileUseCase,
    required CreateGroupUseCase createGroupUseCase,
    required GetGroupsUseCase getGroupsUseCase,
    required CreatePostUseCase createPostUseCase,
    required GetGlobalFeedUseCase getGlobalFeedUseCase,
    required GetGroupFeedUseCase getGroupFeedUseCase,
    required CreateCommentUseCase createCommentUseCase,
    required GetCommentsUseCase getCommentsUseCase,
    required CreateReportUseCase createReportUseCase,
  })  : _getSocialProfileUseCase = getSocialProfileUseCase,
        _createSocialProfileUseCase = createSocialProfileUseCase,
        _createGroupUseCase = createGroupUseCase,
        _getGroupsUseCase = getGroupsUseCase,
        _createPostUseCase = createPostUseCase,
        _getGlobalFeedUseCase = getGlobalFeedUseCase,
        _getGroupFeedUseCase = getGroupFeedUseCase,
        _createCommentUseCase = createCommentUseCase,
        _getCommentsUseCase = getCommentsUseCase,
        _createReportUseCase = createReportUseCase;

  ForumsStatus _forumsStatus = ForumsStatus.initial;
  ProfileStatus _profileStatus = ProfileStatus.initial;
  CommentsStatus _commentsStatus = CommentsStatus.initial;
  SaveStatus _saveStatus = SaveStatus.initial;

  String? _forumsError;
  String? _profileError;
  String? _commentsError;
  String? _saveError;

  SocialProfile? _socialProfile;
  List<CommunityGroup> _groups = [];
  List<ForumPost> _posts = [];
  List<ForumComment> _comments = [];

  // Getters
  ForumsStatus get forumsStatus => _forumsStatus;
  ProfileStatus get profileStatus => _profileStatus;
  CommentsStatus get commentsStatus => _commentsStatus;
  SaveStatus get saveStatus => _saveStatus;

  String? get forumsError => _forumsError;
  String? get profileError => _profileError;
  String? get commentsError => _commentsError;
  String? get saveError => _saveError;

  SocialProfile? get socialProfile => _socialProfile;
  List<CommunityGroup> get groups => _groups;
  List<ForumPost> get posts => _posts;
  List<ForumComment> get comments => _comments;

  // Compatibility getters
  bool get isForumsLoading => _forumsStatus == ForumsStatus.loading;
  bool get isProfileLoading => _profileStatus == ProfileStatus.loading;
  bool get isCommentsLoading => _commentsStatus == CommentsStatus.loading;
  bool get isSaving => _saveStatus == SaveStatus.loading;

  // Fetch social profile
  Future<void> loadSocialProfile(int userId) async {
    _profileStatus = ProfileStatus.loading;
    _profileError = null;
    notifyListeners();

    try {
      _socialProfile = await _getSocialProfileUseCase.call(userId);
      _profileStatus = ProfileStatus.success;
    } catch (e) {
      debugPrint('Error loading social profile: $e');
      _socialProfile = null;
      _profileStatus = ProfileStatus.success;
    } finally {
      notifyListeners();
    }
  }

  // Create or update profile
  Future<bool> saveSocialProfile(SocialProfile profile) async {
    _saveStatus = SaveStatus.loading;
    _saveError = null;
    notifyListeners();

    try {
      _socialProfile = await _createSocialProfileUseCase.call(profile);
      _saveStatus = SaveStatus.success;
      return true;
    } catch (e) {
      _saveError = e.toString();
      _saveStatus = SaveStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Load Groups
  Future<void> loadGroups() async {
    _forumsStatus = ForumsStatus.loading;
    _forumsError = null;
    notifyListeners();

    try {
      _groups = await _getGroupsUseCase.call();
      _forumsStatus = ForumsStatus.success;
    } catch (e) {
      _forumsError = e.toString();
      _forumsStatus = ForumsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // Create group
  Future<bool> createGroup(String name, String description, int createdBy) async {
    _saveStatus = SaveStatus.loading;
    _saveError = null;
    notifyListeners();

    try {
      final newGroup = CommunityGroup(
        groupId: 0,
        name: name,
        description: description,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      final created = await _createGroupUseCase.call(newGroup);
      _groups.insert(0, created);
      _saveStatus = SaveStatus.success;
      return true;
    } catch (e) {
      _saveError = e.toString();
      _saveStatus = SaveStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Load Global Feed
  Future<void> loadGlobalFeed() async {
    _forumsStatus = ForumsStatus.loading;
    _forumsError = null;
    notifyListeners();

    try {
      _posts = await _getGlobalFeedUseCase.call();
      _forumsStatus = ForumsStatus.success;
    } catch (e) {
      _forumsError = e.toString();
      _forumsStatus = ForumsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // Load Group Feed
  Future<void> loadGroupFeed(int groupId) async {
    _forumsStatus = ForumsStatus.loading;
    _forumsError = null;
    notifyListeners();

    try {
      _posts = await _getGroupFeedUseCase.call(groupId);
      _forumsStatus = ForumsStatus.success;
    } catch (e) {
      _forumsError = e.toString();
      _forumsStatus = ForumsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // Create post
  Future<bool> createPost(int authorId, int? groupId, String title, String content) async {
    _saveStatus = SaveStatus.loading;
    _saveError = null;
    notifyListeners();

    try {
      final newPost = ForumPost(
        postId: 0,
        authorId: authorId,
        groupId: groupId,
        title: title,
        content: content,
        createdAt: DateTime.now(),
      );
      final created = await _createPostUseCase.call(newPost);
      _posts.insert(0, created);
      _saveStatus = SaveStatus.success;
      return true;
    } catch (e) {
      _saveError = e.toString();
      _saveStatus = SaveStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Load Comments
  Future<void> loadComments(int postId) async {
    _commentsStatus = CommentsStatus.loading;
    _commentsError = null;
    notifyListeners();

    try {
      _comments = await _getCommentsUseCase.call(postId);
      _commentsStatus = CommentsStatus.success;
    } catch (e) {
      _commentsError = e.toString();
      _commentsStatus = CommentsStatus.error;
    } finally {
      notifyListeners();
    }
  }

  // Add Comment
  Future<bool> createComment(int postId, int authorId, String content) async {
    _saveStatus = SaveStatus.loading;
    _saveError = null;
    notifyListeners();

    try {
      final newComment = ForumComment(
        commentId: 0,
        postId: postId,
        authorId: authorId,
        content: content,
        createdAt: DateTime.now(),
      );
      final created = await _createCommentUseCase.call(newComment);
      _comments.add(created);
      _saveStatus = SaveStatus.success;
      return true;
    } catch (e) {
      _saveError = e.toString();
      _saveStatus = SaveStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Create Report
  Future<bool> createReport(int reporterId, int? postId, int? commentId, String reason) async {
    _saveStatus = SaveStatus.loading;
    _saveError = null;
    notifyListeners();

    try {
      final newReport = ForumReport(
        reporterId: reporterId,
        postId: postId,
        commentId: commentId,
        reason: reason,
      );
      await _createReportUseCase.call(newReport);
      _saveStatus = SaveStatus.success;
      return true;
    } catch (e) {
      _saveError = e.toString();
      _saveStatus = SaveStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }
}
