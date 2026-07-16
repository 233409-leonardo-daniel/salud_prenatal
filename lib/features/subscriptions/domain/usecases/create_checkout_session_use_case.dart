import '../repositories/subscriptions_repository.dart';

class CreateCheckoutSessionUseCase {
  final SubscriptionsRepository repository;

  CreateCheckoutSessionUseCase(this.repository);

  Future<String> call(String planType, String paymentMode) {
    return repository.createCheckoutSession(planType, paymentMode);
  }
}
