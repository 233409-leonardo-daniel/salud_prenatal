import '../../domain/entities/social_profile.dart';
import '../../domain/entities/profile_timeline.dart';
import '../../domain/entities/community_group.dart';
import '../../domain/entities/forum_post.dart';
import '../../domain/entities/forum_comment.dart';
import '../../domain/entities/forum_report.dart';
import '../../domain/repositories/forums_repository.dart';
import '../datasources/forums_remote_data_source.dart';
import '../models/social_profile_model.dart';
import '../models/community_group_model.dart';
import '../models/forum_post_model.dart';
import '../models/forum_comment_model.dart';
import '../models/forum_report_model.dart';

class ForumsRepositoryImpl implements ForumsRepository {
  final ForumsRemoteDataSource remoteDataSource;

  ForumsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SocialProfile> getSocialProfile(int userId) {
    return remoteDataSource.getSocialProfile(userId);
  }

  @override
  Future<SocialProfile> createOrUpdateSocialProfile(SocialProfile profile) {
    return remoteDataSource.createOrUpdateSocialProfile(SocialProfileModel.fromEntity(profile));
  }

  @override
  Future<SocialProfile> updateSocialProfile(SocialProfile profile) {
    return remoteDataSource.updateSocialProfile(SocialProfileModel.fromEntity(profile));
  }

  @override
  Future<ProfileTimeline> getProfileTimeline(int userId, {int limit = 50, int offset = 0}) {
    return remoteDataSource.getProfileTimeline(userId, limit: limit, offset: offset);
  }

  @override
  Future<CommunityGroup> createGroup(CommunityGroup group) {
    return remoteDataSource.createGroup(CommunityGroupModel.fromEntity(group));
  }

  @override
  Future<List<CommunityGroup>> getGroups() async {
    return await remoteDataSource.getGroups();
  }

  @override
  Future<List<CommunityGroup>> getRecommendedGroups() async {
    return await remoteDataSource.getRecommendedGroups();
  }

  @override
  Future<ForumPost> createPost(ForumPost post) {
    return remoteDataSource.createPost(ForumPostModel.fromEntity(post));
  }

  @override
  Future<List<ForumPost>> getGlobalFeed(int limit, int offset) async {
    return await remoteDataSource.getGlobalFeed(limit, offset);
  }

  @override
  Future<List<ForumPost>> getRecommendedFeed(int limit, int offset) async {
    return await remoteDataSource.getRecommendedFeed(limit, offset);
  }

  @override
  Future<List<ForumPost>> getGroupFeed(int groupId, int limit, int offset) async {
    return await remoteDataSource.getGroupFeed(groupId, limit, offset);
  }

  @override
  Future<ForumComment> createComment(ForumComment comment) {
    return remoteDataSource.createComment(ForumCommentModel.fromEntity(comment));
  }

  @override
  Future<List<ForumComment>> getComments(int postId) async {
    return await remoteDataSource.getComments(postId);
  }

  @override
  Future<void> createReport(ForumReport report) {
    return remoteDataSource.createReport(ForumReportModel.fromEntity(report));
  }
}
