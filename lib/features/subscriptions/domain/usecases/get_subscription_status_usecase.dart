import '../entities/subscription_status.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionStatusUsecase {
  final SubscriptionsRepository repository;

  GetSubscriptionStatusUsecase(this.repository);

  Future<SubscriptionStatus> call() {
    return repository.getStatus();
  }
}
