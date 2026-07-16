import '../../../../core/network/api_client.dart';
import '../data/datasources/forums_remote_data_source.dart';
import '../data/repositories/forums_repository_impl.dart';
import '../domain/repositories/forums_repository.dart';
import '../domain/usecases/get_social_profile_use_case.dart';
import '../domain/usecases/create_social_profile_use_case.dart';
import '../domain/usecases/update_social_profile_use_case.dart';
import '../domain/usecases/get_profile_timeline_use_case.dart';
import '../domain/usecases/create_group_use_case.dart';
import '../domain/usecases/get_groups_use_case.dart';
import '../domain/usecases/create_post_use_case.dart';
import '../domain/usecases/get_global_feed_use_case.dart';
import '../domain/usecases/get_recommended_feed_use_case.dart';
import '../domain/usecases/get_recommended_groups_use_case.dart';
import '../domain/usecases/get_group_feed_use_case.dart';
import '../domain/usecases/create_comment_use_case.dart';
import '../domain/usecases/get_comments_use_case.dart';
import '../domain/usecases/create_report_use_case.dart';

class ForumsModule {
  late final ForumsRepository repository;
  late final GetSocialProfileUseCase getSocialProfileUseCase;
  late final CreateSocialProfileUseCase createSocialProfileUseCase;
  late final UpdateSocialProfileUseCase updateSocialProfileUseCase;
  late final GetProfileTimelineUseCase getProfileTimelineUseCase;
  late final CreateGroupUseCase createGroupUseCase;
  late final GetGroupsUseCase getGroupsUseCase;
  late final GetRecommendedGroupsUseCase getRecommendedGroupsUseCase;
  late final CreatePostUseCase createPostUseCase;
  late final GetGlobalFeedUseCase getGlobalFeedUseCase;
  late final GetRecommendedFeedUseCase getRecommendedFeedUseCase;
  late final GetGroupFeedUseCase getGroupFeedUseCase;
  late final CreateCommentUseCase createCommentUseCase;
  late final GetCommentsUseCase getCommentsUseCase;
  late final CreateReportUseCase createReportUseCase;

  ForumsModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    final remoteDataSource = ForumsRemoteDataSourceImpl(apiClient: apiClient);
    repository = ForumsRepositoryImpl(remoteDataSource: remoteDataSource);

    getSocialProfileUseCase = GetSocialProfileUseCase(repository);
    createSocialProfileUseCase = CreateSocialProfileUseCase(repository);
    updateSocialProfileUseCase = UpdateSocialProfileUseCase(repository);
    getProfileTimelineUseCase = GetProfileTimelineUseCase(repository);
    createGroupUseCase = CreateGroupUseCase(repository);
    getGroupsUseCase = GetGroupsUseCase(repository);
    getRecommendedGroupsUseCase = GetRecommendedGroupsUseCase(repository);
    createPostUseCase = CreatePostUseCase(repository);
    getGlobalFeedUseCase = GetGlobalFeedUseCase(repository);
    getRecommendedFeedUseCase = GetRecommendedFeedUseCase(repository);
    getGroupFeedUseCase = GetGroupFeedUseCase(repository);
    createCommentUseCase = CreateCommentUseCase(repository);
    getCommentsUseCase = GetCommentsUseCase(repository);
    createReportUseCase = CreateReportUseCase(repository);
  }
}
