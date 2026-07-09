import '../../domain/entities/subscription_status.dart';

class SubscriptionStatusModel extends SubscriptionStatus {
  SubscriptionStatusModel({
    required super.status,
    super.planType,
    super.currentPeriodEnd,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      status: json['status'] ?? 'pending',
      planType: json['plan_type'],
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.tryParse(json['current_period_end'])
          : null,
    );
  }
}
