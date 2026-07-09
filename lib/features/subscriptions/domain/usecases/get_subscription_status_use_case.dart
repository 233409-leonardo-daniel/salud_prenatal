import '../entities/subscription_status.dart';
import '../repositories/subscriptions_repository.dart';

class GetSubscriptionStatusUseCase {
  final SubscriptionsRepository repository;

  GetSubscriptionStatusUseCase(this.repository);

  Future<SubscriptionStatus> call() {
    return repository.getStatus();
  }
}
