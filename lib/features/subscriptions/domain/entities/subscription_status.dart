class SubscriptionStatus {
  final String status;
  final String? planType;
  final DateTime? currentPeriodEnd;

  SubscriptionStatus({
    required this.status,
    this.planType,
    this.currentPeriodEnd,
  });

  bool get isActive => status == 'active';
}
