class SubscriptionStatus {
  final String status;
  final String? planType;
  final DateTime? currentPeriodEnd;

  /// `true` -> suscripción recurrente con tarjeta (se renueva sola cada mes).
  /// `false` -> pago único (OXXO/SPEI o tarjeta suelta): al llegar
  /// [currentPeriodEnd] el acceso expira y el doctor debe volver a pagar.
  /// Se asume `true` cuando el backend no lo informa, para no mostrar avisos
  /// de vencimiento falsos a suscripciones recurrentes antiguas.
  final bool autoRenewal;

  /// `true` mientras una suscripción recurrente sigue `active` pero ya está
  /// marcada para cancelarse en [currentPeriodEnd].
  final bool cancelAtPeriodEnd;

  SubscriptionStatus({
    required this.status,
    this.planType,
    this.currentPeriodEnd,
    this.autoRenewal = true,
    this.cancelAtPeriodEnd = false,
  });

  bool get isActive => status == 'active';

  /// Activa pero sin renovación automática: hay que avisar del vencimiento.
  bool get isOneTimeActive => isActive && !autoRenewal;
}
