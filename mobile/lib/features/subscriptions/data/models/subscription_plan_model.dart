class SubscriptionPlanModel {
  final String id;
  final String name;
  final String planType;
  final int pricePkr;
  final int durationDays;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.planType,
    required this.pricePkr,
    required this.durationDays,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Plan',
      planType: json['planType'] as String? ?? 'YEAR_1',
      pricePkr: json['pricePkr'] as int? ?? 0,
      durationDays: json['durationDays'] as int? ?? 365,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'planType': planType,
      'pricePkr': pricePkr,
      'durationDays': durationDays,
    };
  }
}
