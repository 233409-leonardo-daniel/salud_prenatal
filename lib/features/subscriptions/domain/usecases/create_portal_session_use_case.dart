import '../repositories/subscriptions_repository.dart';

class CreatePortalSessionUseCase {
  final SubscriptionsRepository repository;

  CreatePortalSessionUseCase(this.repository);

  Future<String> call() {
    return repository.createPortalSession();
  }
}
