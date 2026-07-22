import '../../../core/network/api_client.dart';
import '../data/datasources/subscriptions_remote_data_source.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_subscription_status_use_case.dart';
import '../domain/usecases/create_checkout_session_use_case.dart';
import '../domain/usecases/create_portal_session_use_case.dart';
import '../domain/usecases/refresh_token_use_case.dart';

class SubscriptionsModule {
  late final SubscriptionsRepository repository;
  late final GetSubscriptionStatusUseCase getSubscriptionStatusUseCase;
  late final CreateCheckoutSessionUseCase createCheckoutSessionUseCase;
  late final CreatePortalSessionUseCase createPortalSessionUseCase;
  late final RefreshTokenUseCase refreshTokenUseCase;

  SubscriptionsModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    final remoteDataSource = SubscriptionsRemoteDataSourceImpl(apiClient: apiClient);
    repository = SubscriptionsRepositoryImpl(remoteDataSource: remoteDataSource);

    getSubscriptionStatusUseCase = GetSubscriptionStatusUseCase(repository);
    createCheckoutSessionUseCase = CreateCheckoutSessionUseCase(repository);
    createPortalSessionUseCase = CreatePortalSessionUseCase(repository);
    refreshTokenUseCase = RefreshTokenUseCase(repository);
  }
}
