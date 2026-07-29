import '../repositories/subscriptions_repository.dart';

class CreateCheckoutSessionUsecase {
  final SubscriptionsRepository repository;

  CreateCheckoutSessionUsecase(this.repository);

  Future<String> call(String planType, String paymentMode) {
    return repository.createCheckoutSession(planType, paymentMode);
  }
}
