import '../entities/social_profile.dart';
import '../entities/community_group.dart';
import '../entities/forum_post.dart';
import '../entities/forum_comment.dart';
import '../entities/forum_report.dart';

abstract class ForumsRepository {
  Future<SocialProfile> getSocialProfile(int userId);
  Future<SocialProfile> createOrUpdateSocialProfile(SocialProfile profile);
  Future<CommunityGroup> createGroup(CommunityGroup group);
  Future<List<CommunityGroup>> getGroups();
  Future<ForumPost> createPost(ForumPost post);
  Future<List<ForumPost>> getGlobalFeed(int limit, int offset);
  Future<List<ForumPost>> getGroupFeed(int groupId, int limit, int offset);
  Future<ForumComment> createComment(ForumComment comment);
  Future<List<ForumComment>> getComments(int postId);
  Future<void> createReport(ForumReport report);
}
