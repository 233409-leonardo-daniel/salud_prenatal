import '../repositories/subscriptions_repository.dart';

class CreateCheckoutSessionUseCase {
  final SubscriptionsRepository repository;

  CreateCheckoutSessionUseCase(this.repository);

  Future<String> call(String planType) {
    return repository.createCheckoutSession(planType);
  }
}
