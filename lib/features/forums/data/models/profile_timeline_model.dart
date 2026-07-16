import '../../domain/entities/profile_timeline.dart';
import 'social_profile_model.dart';
import 'forum_post_model.dart';

class ProfileTimelineModel extends ProfileTimeline {
  ProfileTimelineModel({
    required super.profile,
    required super.posts,
  });

  factory ProfileTimelineModel.fromJson(Map<String, dynamic> json) {
    final postsJson = json['posts'] as List<dynamic>? ?? [];
    return ProfileTimelineModel(
      profile: SocialProfileModel.fromJson(json['profile'] ?? {}),
      posts: postsJson.map((e) => ForumPostModel.fromJson(e)).toList(),
    );
  }
}
