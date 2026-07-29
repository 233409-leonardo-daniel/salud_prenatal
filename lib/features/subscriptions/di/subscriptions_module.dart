import '../../../core/network/api_client.dart';
import '../data/datasources/subscriptions_remote_data_source.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_subscription_status_usecase.dart';
import '../domain/usecases/create_checkout_session_usecase.dart';
import '../domain/usecases/create_portal_session_usecase.dart';
import '../domain/usecases/refresh_token_usecase.dart';

class SubscriptionsModule {
  late final SubscriptionsRepository repository;
  late final GetSubscriptionStatusUsecase getSubscriptionStatusUseCase;
  late final CreateCheckoutSessionUsecase createCheckoutSessionUseCase;
  late final CreatePortalSessionUsecase createPortalSessionUseCase;
  late final RefreshTokenUsecase refreshTokenUseCase;

  SubscriptionsModule(ApiClient apiClient) {
    _initDependencies(apiClient);
  }

  void _initDependencies(ApiClient apiClient) {
    final remoteDataSource = SubscriptionsRemoteDataSourceImpl(apiClient: apiClient);
    repository = SubscriptionsRepositoryImpl(remoteDataSource: remoteDataSource);

    getSubscriptionStatusUseCase = GetSubscriptionStatusUsecase(repository);
    createCheckoutSessionUseCase = CreateCheckoutSessionUsecase(repository);
    createPortalSessionUseCase = CreatePortalSessionUsecase(repository);
    refreshTokenUseCase = RefreshTokenUsecase(repository);
  }
}
