import '../entities/subscription_status.dart';

abstract class SubscriptionsRepository {
  Future<SubscriptionStatus> getStatus();
  Future<String> createCheckoutSession(String planType);
}
