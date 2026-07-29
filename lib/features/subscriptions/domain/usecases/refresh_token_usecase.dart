import '../repositories/subscriptions_repository.dart';

/// Reobtiene un JWT fresco tras activarse la suscripción, para que el gating
/// (que lee `subscription_status` del token) refleje el nuevo estado.
class RefreshTokenUsecase {
  final SubscriptionsRepository repository;

  RefreshTokenUsecase(this.repository);

  Future<String> call() {
    return repository.refreshToken();
  }
}
