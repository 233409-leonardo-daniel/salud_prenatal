import '../repositories/subscriptions_repository.dart';

/// Reobtiene un JWT fresco tras activarse la suscripción, para que el gating
/// (que lee `subscription_status` del token) refleje el nuevo estado.
class RefreshTokenUseCase {
  final SubscriptionsRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<String> call() {
    return repository.refreshToken();
  }
}
