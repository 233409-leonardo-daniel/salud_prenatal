import 'package:flutter/material.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/subscription_status.dart';
import '../../domain/usecases/get_subscription_status_use_case.dart';
import '../../domain/usecases/create_checkout_session_use_case.dart';
import '../../domain/usecases/refresh_token_use_case.dart';
import '../pages/subscription_state.dart';

class SubscriptionsProvider with ChangeNotifier {
  final GetSubscriptionStatusUseCase _getSubscriptionStatusUseCase;
  final CreateCheckoutSessionUseCase _createCheckoutSessionUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final SessionManager _session;

  SubscriptionsProvider({
    required GetSubscriptionStatusUseCase getSubscriptionStatusUseCase,
    required CreateCheckoutSessionUseCase createCheckoutSessionUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required SessionManager session,
  })  : _getSubscriptionStatusUseCase = getSubscriptionStatusUseCase,
        _createCheckoutSessionUseCase = createCheckoutSessionUseCase,
        _refreshTokenUseCase = refreshTokenUseCase,
        _session = session;

  SubscriptionFetchStatus _fetchStatus = SubscriptionFetchStatus.initial;
  CheckoutStatus _checkoutStatus = CheckoutStatus.initial;
  String? _fetchError;
  String? _checkoutError;
  SubscriptionStatus? _subscription;

  SubscriptionFetchStatus get fetchStatus => _fetchStatus;
  CheckoutStatus get checkoutStatus => _checkoutStatus;
  String? get fetchError => _fetchError;
  String? get checkoutError => _checkoutError;
  SubscriptionStatus? get subscription => _subscription;

  Future<void> loadStatus() async {
    _fetchStatus = SubscriptionFetchStatus.loading;
    _fetchError = null;
    notifyListeners();

    try {
      _subscription = await _getSubscriptionStatusUseCase.call();
      _fetchStatus = SubscriptionFetchStatus.success;
    } catch (e) {
      _fetchError = e.toString().replaceAll('Exception: ', '');
      _fetchStatus = SubscriptionFetchStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// [paymentMode]: `"recurring"` (tarjeta) o `"one_time"` (habilita OXXO/SPEI).
  Future<String?> startCheckout(String planType, String paymentMode) async {
    _checkoutStatus = CheckoutStatus.loading;
    _checkoutError = null;
    notifyListeners();

    try {
      final checkoutUrl =
          await _createCheckoutSessionUseCase.call(planType, paymentMode);
      _checkoutStatus = CheckoutStatus.success;
      notifyListeners();
      return checkoutUrl;
    } catch (e) {
      _checkoutError = e.toString().replaceAll('Exception: ', '');
      _checkoutStatus = CheckoutStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Tras confirmarse el pago (`status == active`), reemplaza el JWT guardado
  /// para que el gating deje de bloquear. Best-effort: si falla, el token viejo
  /// sigue vigente y el usuario puede reintentar. No lanza.
  Future<void> refreshSessionToken() async {
    try {
      final newToken = await _refreshTokenUseCase.call();
      await _session.applyRefreshedToken(newToken, subscriptionStatus: 'active');
    } catch (e) {
      debugPrint('SubscriptionsProvider: refresh de token falló: $e');
    }
  }
}
