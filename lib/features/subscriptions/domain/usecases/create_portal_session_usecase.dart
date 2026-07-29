import '../repositories/subscriptions_repository.dart';

class CreatePortalSessionUsecase {
  final SubscriptionsRepository repository;

  CreatePortalSessionUsecase(this.repository);

  Future<String> call() {
    return repository.createPortalSession();
  }
}
