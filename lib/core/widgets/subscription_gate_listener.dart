import 'dart:async';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../../app.dart';

/// Escucha las respuestas 402 (suscripción de doctor inactiva) que emite
/// [ApiClient] desde cualquier request y redirige a la pantalla de
/// suscripción, igual que [SessionTimeoutListener] hace para el logout
/// automático.
class SubscriptionGateListener extends StatefulWidget {
  final Widget child;

  const SubscriptionGateListener({super.key, required this.child});

  @override
  State<SubscriptionGateListener> createState() => _SubscriptionGateListenerState();
}

class _SubscriptionGateListenerState extends State<SubscriptionGateListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ApiClient.onPaymentRequired.listen((_) => _redirectToSubscription());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _redirectToSubscription() {
    final navigatorState = MyApp.navigatorKey.currentState;
    final currentContext = MyApp.navigatorKey.currentContext;
    if (navigatorState == null || currentContext == null) return;

    final currentRoute = ModalRoute.of(currentContext)?.settings.name;
    if (currentRoute == '/subscription') return;

    navigatorState.pushNamed('/subscription');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
