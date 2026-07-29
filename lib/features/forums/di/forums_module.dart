import '../../../../core/network/api_client.dart';
import '../data/datasources/forums_remote_data_source.dart';
import '../data/repositories/forums_repository_impl.dart';
import '../domain/repositories/forums_repository.dart';
import '../domain/usecases/get_social_profile_usecase.dart';
import '../domain/usecases/create_social_profile_usecase.dart';
import '../domain/usecases/update_social_profile_usecase.dart';
import '../domain/usecases/get_profile_timeline_usecase.dart';
import '../domain/usecases/create_group_usecase.dart';
import '../domain/usecases/get_groups_usecase.dart';
import '../domain/usecases/create_post_usecase.dart';
import '../domain/usecases/upload_post_image_usecase.dart';
import '../domain/usecases/upload_avatar_usecase.dart';
import '../domain/usecases/get_global_feed_usecase.dart';
import '../domain/usecases/get_recommended_feed_usecase.dart';
import '../domain/usecases/get_recommended_groups_usecase.dart';
import '../domain/usecases/get_group_feed_usecase.dart';
import '../domain/usecases/create_comment_usecase.dart';
import '../domain/usecases/get_comments_usecase.dart';
import '../domain/usecases/create_report_usecase.dart';

class ForumsModule {
  late final ForumsRepository repository;
  late final GetSocialProfileUsecase getSocialProfileUseCase;
  late final CreateSocialProfileUsecase createSocialProfileUseCase;
  late final UpdateSocialProfileUsecase updateSocialProfileUseCase;
  late final GetProfileTimelineUsecase getProfileTimelineUseCase;
  late final CreateGroupUsecase createGroupUseCase;
  late final GetGroupsUsecase getGroupsUseCase;
  late final GetRecommendedGroupsUsecase getRecommendedGroupsUseCase;
  late final CreatePostUsecase createPostUseCase;
  late final UploadPostImageUsecase uploadPostImageUseCase;
  late final UploadAvatarUsecase uploadAvatarUseCase;
  late final GetGlobalFeedUsecase getGlobalFeedUseCase;
  late final GetRecommendedFeedUsecase getRecommendedFeedUseCase;
  late final GetGroupFeedUsecase getGroupFeedUseCase;
  late final CreateCommentUsecase createCommentUseCase;
  late final GetCommentsUsecase getCommentsUseCase;
  late final CreateReportUsecase createReportUseCase;

  ForumsModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    final remoteDataSource = ForumsRemoteDataSourceImpl(apiClient: apiClient);
    repository = ForumsRepositoryImpl(remoteDataSource: remoteDataSource);

    getSocialProfileUseCase = GetSocialProfileUsecase(repository);
    createSocialProfileUseCase = CreateSocialProfileUsecase(repository);
    updateSocialProfileUseCase = UpdateSocialProfileUsecase(repository);
    getProfileTimelineUseCase = GetProfileTimelineUsecase(repository);
    createGroupUseCase = CreateGroupUsecase(repository);
    getGroupsUseCase = GetGroupsUsecase(repository);
    getRecommendedGroupsUseCase = GetRecommendedGroupsUsecase(repository);
    createPostUseCase = CreatePostUsecase(repository);
    uploadPostImageUseCase = UploadPostImageUsecase(repository);
    uploadAvatarUseCase = UploadAvatarUsecase(repository);
    getGlobalFeedUseCase = GetGlobalFeedUsecase(repository);
    getRecommendedFeedUseCase = GetRecommendedFeedUsecase(repository);
    getGroupFeedUseCase = GetGroupFeedUsecase(repository);
    createCommentUseCase = CreateCommentUsecase(repository);
    getCommentsUseCase = GetCommentsUsecase(repository);
    createReportUseCase = CreateReportUsecase(repository);
  }
}
