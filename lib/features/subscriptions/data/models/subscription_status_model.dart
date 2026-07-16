import '../../domain/entities/subscription_status.dart';

class SubscriptionStatusModel extends SubscriptionStatus {
  SubscriptionStatusModel({
    required super.status,
    super.planType,
    super.currentPeriodEnd,
    super.autoRenewal,
    super.cancelAtPeriodEnd,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      status: json['status'] ?? 'pending',
      planType: json['plan_type'],
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'])
          : null,
      // Ausente en respuestas antiguas -> se asume recurrente (true) para no
      // mostrar el aviso de "pago único / vence" a suscripciones con tarjeta.
      autoRenewal: json['auto_renewal'] is bool ? json['auto_renewal'] : true,
      cancelAtPeriodEnd:
          json['cancel_at_period_end'] is bool ? json['cancel_at_period_end'] : false,
    );
  }
}
