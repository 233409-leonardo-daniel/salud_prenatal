import '../entities/social_profile.dart';
import '../entities/profile_timeline.dart';
import '../entities/community_group.dart';
import '../entities/forum_post.dart';
import 'dart:io';
import '../entities/forum_comment.dart';
import '../entities/forum_report.dart';

abstract class ForumsRepository {
  Future<SocialProfile> getSocialProfile(int userId);
  Future<SocialProfile> createOrUpdateSocialProfile(SocialProfile profile);
  Future<SocialProfile> updateSocialProfile(SocialProfile profile);
  Future<ProfileTimeline> getProfileTimeline(int userId, {int limit = 50, int offset = 0});
  Future<CommunityGroup> createGroup(CommunityGroup group);
  Future<List<CommunityGroup>> getGroups();
  Future<List<CommunityGroup>> getRecommendedGroups();
  Future<String> uploadPostImage(File file);
  Future<ForumPost> createPost(ForumPost post);
  Future<List<ForumPost>> getGlobalFeed(int limit, int offset);
  Future<List<ForumPost>> getRecommendedFeed(int limit, int offset);
  Future<List<ForumPost>> getGroupFeed(int groupId, int limit, int offset);
  Future<ForumComment> createComment(ForumComment comment);
  Future<List<ForumComment>> getComments(int postId);
  Future<void> createReport(ForumReport report);
}
