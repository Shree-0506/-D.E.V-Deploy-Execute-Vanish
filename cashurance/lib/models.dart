enum PolicyStatus { active, inactive }

enum EventSeverity { normal, severe, catastrophic }

enum PayoutStatus { paid, pending, rejected }

enum ZoneStatus { watchlist, triggered, stable }

enum TriggerEventType { flood, heat, aqi, traffic }

class DeliveryPlatform {
  const DeliveryPlatform(this.name, this.id);

  final String name;
  final String id;

  static const List<DeliveryPlatform> all = [
    DeliveryPlatform('Zepto', 'zepto'),
    DeliveryPlatform('Blinkit', 'blinkit'),
    DeliveryPlatform('Swiggy Instamart', 'swiggy'),
    DeliveryPlatform('Zomato', 'zomato'),
    DeliveryPlatform('Other', 'other'),
  ];
}

class RiderProfile {
  RiderProfile({
    required this.name,
    required this.phone,
    required this.platform,
    required this.upiId,
    required this.zoneName,
    this.latitude = 12.9716,
    this.longitude = 77.5946,
    this.zoneRadius = 2.5,
    this.policiesPurchased = 0,
    this.payoutsSettled = 0,
    this.avgSettlementSeconds = 258,
  });

  String name;
  String phone;
  String platform;
  String upiId;
  String zoneName;
  double latitude;
  double longitude;
  double zoneRadius;
  int policiesPurchased;
  int payoutsSettled;
  int avgSettlementSeconds;

  String get avgSettlementFormatted {
    final m = avgSettlementSeconds ~/ 60;
    final s = avgSettlementSeconds % 60;
    return '${m}m ${s}s';
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.eventAlerts = true,
    this.weeklyReminders = true,
    this.payoutNotifs = true,
  });

  final bool eventAlerts;
  final bool weeklyReminders;
  final bool payoutNotifs;

  NotificationPreferences copyWith({
    bool? eventAlerts,
    bool? weeklyReminders,
    bool? payoutNotifs,
  }) {
    return NotificationPreferences(
      eventAlerts: eventAlerts ?? this.eventAlerts,
      weeklyReminders: weeklyReminders ?? this.weeklyReminders,
      payoutNotifs: payoutNotifs ?? this.payoutNotifs,
    );
  }
}

class WeeklyPolicy {
  WeeklyPolicy({
    required this.weekStart,
    required this.premiumPaid,
    required this.zoneName,
    this.status = PolicyStatus.active,
  });

  final DateTime weekStart;
  final double premiumPaid;
  final String zoneName;
  final PolicyStatus status;

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(weekEnd)) return 0;
    return weekEnd.difference(now).inDays;
  }

  String get coverageBadge {
    String fmt(DateTime d) => '${d.day}/${d.month}';
    return 'Sun-Sat  ${fmt(weekStart)} - ${fmt(weekEnd)}';
  }
}

class PremiumBreakdown {
  const PremiumBreakdown({
    this.baseRate = 20.0,
    this.zoneRisk = 12.0,
    this.weatherVolatility = 8.0,
    this.mobilityRisk = 5.0,
    this.safetyDiscount = 5.0,
    this.aiReason =
        'Moderate rain forecast and elevated traffic in your zone this week.',
    this.modelName = 'rule-based-v1',
    this.modelConfidence = 0.75,
  });

  final double baseRate;
  final double zoneRisk;
  final double weatherVolatility;
  final double mobilityRisk;
  final double safetyDiscount;
  final String aiReason;
  final String modelName;
  final double modelConfidence;

  double get total =>
      baseRate + zoneRisk + weatherVolatility + mobilityRisk - safetyDiscount;
}

class RiskFeedItem {
  const RiskFeedItem({
    required this.label,
    required this.level,
    required this.icon,
  });

  final String label;
  final String level;
  final String icon;
}

class TriggerAlert {
  const TriggerAlert({
    required this.eventType,
    required this.severity,
    required this.zoneStatus,
    required this.eventId,
    required this.dataSource,
    required this.timestamp,
    this.metricSummary = '',
  });

  final TriggerEventType eventType;
  final EventSeverity severity;
  final ZoneStatus zoneStatus;
  final String eventId;
  final String dataSource;
  final DateTime timestamp;
  final String metricSummary;

  String get eventTypeLabel {
    switch (eventType) {
      case TriggerEventType.flood:
        return 'Flood';
      case TriggerEventType.heat:
        return 'Heatwave';
      case TriggerEventType.aqi:
        return 'AQI Spike';
      case TriggerEventType.traffic:
        return 'Traffic Collapse';
    }
  }

  String get severityLabel {
    switch (severity) {
      case EventSeverity.normal:
        return 'Normal';
      case EventSeverity.severe:
        return 'Severe';
      case EventSeverity.catastrophic:
        return 'Catastrophic';
    }
  }

  double get severityMultiplier {
    switch (severity) {
      case EventSeverity.normal:
        return 1.0;
      case EventSeverity.severe:
        return 1.25;
      case EventSeverity.catastrophic:
        return 1.5;
    }
  }

  double get computedPayout {
    const frb = 500.0;
    const irb = 0.0;
    return (frb * severityMultiplier) + irb;
  }
}

class PayoutRecord {
  const PayoutRecord({
    required this.eventType,
    required this.eventDate,
    required this.amount,
    required this.status,
    required this.triggerReason,
    required this.dataSource,
    required this.eventId,
  });

  final String eventType;
  final DateTime eventDate;
  final double amount;
  final PayoutStatus status;
  final String triggerReason;
  final String dataSource;
  final String eventId;

  String get statusLabel {
    switch (status) {
      case PayoutStatus.paid:
        return 'Paid';
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.rejected:
        return 'Rejected';
    }
  }
}

class PaymentSummary {
  const PaymentSummary({
    this.lastPayDate,
    this.lastPayoutDate,
    this.daysRemaining = 0,
    this.payAmount = 0,
    this.payDue = 0,
    this.payDueDate,
  });

  final DateTime? lastPayDate;
  final DateTime? lastPayoutDate;
  final int daysRemaining;
  final double payAmount;
  final double payDue;
  final DateTime? payDueDate;
}
