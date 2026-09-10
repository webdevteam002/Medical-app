class UserSubscriptionItem {
  final String id;
  final String planName;
  final String planType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  const UserSubscriptionItem({
    required this.id,
    required this.planName,
    required this.planType,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory UserSubscriptionItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      // PENDING intents have no start/end yet — use a safe sentinel.
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final status = (json['status'] as String? ?? 'ACTIVE').toUpperCase();
    final endDate = parseDate(json['endDate']);

    return UserSubscriptionItem(
      id: json['id'] as String? ?? '',
      planName: json['planName'] as String? ?? 'Subscription Plan',
      planType: json['planType'] as String? ?? 'YEAR_1',
      status: status,
      startDate: parseDate(json['startDate']),
      endDate: status == 'PENDING' && (json['endDate'] == null)
          ? DateTime.now().add(const Duration(days: 365))
          : endDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'planType': planType,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  bool get isActive {
    if (status.toUpperCase() != 'ACTIVE') return false;
    return endDate.isAfter(DateTime.now());
  }
}

class UserSubscriptionsModel {
  final List<UserSubscriptionItem> subscriptions;
  final List<String> accessibleYears;

  const UserSubscriptionsModel({
    required this.subscriptions,
    required this.accessibleYears,
  });

  factory UserSubscriptionsModel.fromJson(Map<String, dynamic> json) {
    var rawSubs = <UserSubscriptionItem>[];
    if (json['subscriptions'] is List) {
      final list = json['subscriptions'] as List;
      rawSubs = list
          .map((item) =>
              UserSubscriptionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var rawYears = <String>[];
    if (json['accessibleYears'] is List) {
      rawYears = (json['accessibleYears'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return UserSubscriptionsModel(
      subscriptions: rawSubs,
      accessibleYears: rawYears,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      'accessibleYears': accessibleYears,
    };
  }
}
