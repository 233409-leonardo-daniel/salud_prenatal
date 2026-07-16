import '../../domain/entities/subscription_status.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_data_source.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource remoteDataSource;

  SubscriptionsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SubscriptionStatus> getStatus() {
    return remoteDataSource.getStatus();
  }

  @override
  Future<String> createCheckoutSession(String planType, String paymentMode) {
    return remoteDataSource.createCheckoutSession(planType, paymentMode);
  }

  @override
  Future<String> refreshToken() {
    return remoteDataSource.refreshToken();
  }
}
