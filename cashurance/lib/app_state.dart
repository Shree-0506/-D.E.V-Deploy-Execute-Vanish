import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'services/api_service.dart';
import 'services/auth_session.dart';

class AppState extends ChangeNotifier {
  RiderProfile profile = RiderProfile(
    name: 'Rider',
    phone: '',
    platform: 'Other',
    upiId: '',
    zoneName: 'Your Area',
    policiesPurchased: 0,
    payoutsSettled: 0,
  );

  bool isLoading = true;
  String? loadError;

  bool zoneConfirmed = false;
  WeeklyPolicy? activePolicy;
  bool get policyActive => activePolicy != null;

  PremiumBreakdown premiumBreakdown = const PremiumBreakdown();

  bool onlineToday = true;

  List<RiskFeedItem> riskFeed = const [];
  List<TriggerAlert> triggerAlerts = const [];
  List<PayoutRecord> payoutHistory = const [];
  PaymentSummary paymentSummary = const PaymentSummary();
  NotificationPreferences notificationPreferences =
      const NotificationPreferences();

  double get monthlyProtectedAmount => payoutHistory
      .where((r) => r.status == PayoutStatus.paid)
      .fold(0.0, (sum, r) => sum + r.amount);

  Future<void> loadFromBackend() async {
    final token = AuthSession.instance.token;
    if (token == null) {
      loadError = 'No active session. Please login again.';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    loadError = null;
    notifyListeners();

    try {
      final data = await ApiService.fetchState(token);

      final profileData = data['profile'] as Map<String, dynamic>? ?? {};
      profile = RiderProfile(
        name: (profileData['name'] ?? 'Rider').toString(),
        phone: (profileData['phone'] ?? '').toString(),
        platform: (profileData['platform'] ?? 'Other').toString(),
        upiId: (profileData['upiId'] ?? '').toString(),
        zoneName: (profileData['zoneName'] ?? profile.zoneName).toString(),
        latitude: (profileData['latitude'] as num?)?.toDouble() ?? profile.latitude,
        longitude:
          (profileData['longitude'] as num?)?.toDouble() ?? profile.longitude,
        zoneRadius: (profileData['zoneRadius'] as num?)?.toDouble() ?? 2.5,
        policiesPurchased:
            (profileData['policiesPurchased'] as num?)?.toInt() ?? 0,
        payoutsSettled: (profileData['payoutsSettled'] as num?)?.toInt() ?? 0,
        avgSettlementSeconds:
            (profileData['avgSettlementSeconds'] as num?)?.toInt() ?? 258,
      );

      zoneConfirmed = data['zoneConfirmed'] == true;
      onlineToday = data['onlineToday'] != false;

      final policyData = data['activePolicy'] as Map<String, dynamic>?;
      activePolicy = _parsePolicy(policyData);

      final premiumData = data['premiumBreakdown'] as Map<String, dynamic>?;
      premiumBreakdown = PremiumBreakdown(
        baseRate: (premiumData?['baseRate'] as num?)?.toDouble() ?? 20.0,
        zoneRisk: (premiumData?['zoneRisk'] as num?)?.toDouble() ?? 12.0,
        weatherVolatility:
            (premiumData?['weatherVolatility'] as num?)?.toDouble() ?? 8.0,
        mobilityRisk: (premiumData?['mobilityRisk'] as num?)?.toDouble() ?? 5.0,
        safetyDiscount:
            (premiumData?['safetyDiscount'] as num?)?.toDouble() ?? 5.0,
        aiReason: (premiumData?['aiReason'] ??
                'Moderate rain forecast and elevated traffic in your zone this week.')
            .toString(),
        modelName: (premiumData?['modelName'] ?? 'rule-based-v1').toString(),
        modelConfidence:
          (premiumData?['modelConfidence'] as num?)?.toDouble() ?? 0.75,
      );

      final prefsData =
          data['notificationPrefs'] as Map<String, dynamic>? ?? const {};
      notificationPreferences = NotificationPreferences(
        eventAlerts: prefsData['eventAlerts'] != false,
        weeklyReminders: prefsData['weeklyReminders'] != false,
        payoutNotifs: prefsData['payoutNotifs'] != false,
      );

      riskFeed = ((data['riskFeed'] as List<dynamic>? ?? const [])
          .map((e) => _parseRiskFeed(e as Map<String, dynamic>))
          .toList());

      triggerAlerts = ((data['triggerAlerts'] as List<dynamic>? ?? const [])
          .map((e) => _parseTriggerAlert(e as Map<String, dynamic>))
          .toList());

      payoutHistory = ((data['payoutHistory'] as List<dynamic>? ?? const [])
          .map((e) => _parsePayoutRecord(e as Map<String, dynamic>))
          .toList());

      paymentSummary = _parsePaymentSummary(
        data['paymentSummary'] as Map<String, dynamic>?,
      );

      isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      isLoading = false;
      loadError = e.message;
      notifyListeners();
    } catch (_) {
      isLoading = false;
      loadError = 'Failed to load app data from backend.';
      notifyListeners();
    }
  }

  Future<bool> confirmZone(
    String zoneName, {
    required double latitude,
    required double longitude,
  }) async {
    final token = AuthSession.instance.token;
    if (token == null) return false;

    final oldZone = profile.zoneName;
    final oldLatitude = profile.latitude;
    final oldLongitude = profile.longitude;
    final oldConfirmed = zoneConfirmed;

    profile.zoneName = zoneName;
    profile.latitude = latitude;
    profile.longitude = longitude;
    zoneConfirmed = true;
    notifyListeners();

    try {
      await ApiService.confirmZone(
        token: token,
        zoneName: zoneName,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (_) {
      profile.zoneName = oldZone;
      profile.latitude = oldLatitude;
      profile.longitude = oldLongitude;
      zoneConfirmed = oldConfirmed;
      notifyListeners();
      return false;
    }
  }

  Future<bool> purchasePolicy() async {
    final token = AuthSession.instance.token;
    if (token == null) return false;

    final now = DateTime.now();
    final dayOfWeek = now.weekday % 7;
    final sunday = now.subtract(Duration(days: dayOfWeek));

    final previousPolicy = activePolicy;
    final previousPaymentSummary = paymentSummary;
    activePolicy = WeeklyPolicy(
      weekStart: DateTime(sunday.year, sunday.month, sunday.day),
      premiumPaid: premiumBreakdown.total,
      zoneName: profile.zoneName,
    );
    paymentSummary = PaymentSummary(
      lastPayDate: DateTime.now(),
      lastPayoutDate: previousPaymentSummary.lastPayoutDate,
      daysRemaining: 7,
      payAmount: premiumBreakdown.total,
      payDue: 0,
      payDueDate: sunday.add(const Duration(days: 7)),
    );
    profile.policiesPurchased++;
    notifyListeners();

    try {
      await ApiService.purchasePolicy(
        token: token,
        premiumPaid: premiumBreakdown.total,
      );
      return true;
    } catch (_) {
      activePolicy = previousPolicy;
      paymentSummary = previousPaymentSummary;
      profile.policiesPurchased--;
      notifyListeners();
      return false;
    }
  }

  void setOnlineToday(bool value) {
    final previous = onlineToday;
    onlineToday = value;
    notifyListeners();

    unawaited(_syncOnlineToday(value, previous));
  }

  Future<void> _syncOnlineToday(bool value, bool previous) async {
    final token = AuthSession.instance.token;
    if (token == null) {
      onlineToday = previous;
      notifyListeners();
      return;
    }

    try {
      await ApiService.setOnlineIntent(token: token, onlineToday: value);
    } catch (_) {
      onlineToday = previous;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String platform,
    required String upiId,
  }) async {
    final token = AuthSession.instance.token;
    if (token == null) return false;

    final previous = RiderProfile(
      name: profile.name,
      phone: profile.phone,
      platform: profile.platform,
      upiId: profile.upiId,
      zoneName: profile.zoneName,
      latitude: profile.latitude,
      longitude: profile.longitude,
      zoneRadius: profile.zoneRadius,
      policiesPurchased: profile.policiesPurchased,
      payoutsSettled: profile.payoutsSettled,
      avgSettlementSeconds: profile.avgSettlementSeconds,
    );

    profile
      ..name = fullName
      ..platform = platform
      ..upiId = upiId;
    notifyListeners();

    try {
      await ApiService.updateProfile(
        token: token,
        fullName: fullName,
        platform: platform,
        upiId: upiId,
      );
      return true;
    } catch (_) {
      profile = previous;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotificationPreferences(NotificationPreferences next) async {
    final token = AuthSession.instance.token;
    if (token == null) return false;

    final previous = notificationPreferences;
    notificationPreferences = next;
    notifyListeners();

    try {
      await ApiService.updateNotificationPreferences(
        token: token,
        eventAlerts: next.eventAlerts,
        weeklyReminders: next.weeklyReminders,
        payoutNotifs: next.payoutNotifs,
      );
      return true;
    } catch (_) {
      notificationPreferences = previous;
      notifyListeners();
      return false;
    }
  }

  Future<String?> updateLocation({
    required String zoneName,
    required double latitude,
    required double longitude,
  }) async {
    final token = AuthSession.instance.token;
    if (token == null) return 'No active session. Please login again.';

    final oldZone = profile.zoneName;
    final oldLatitude = profile.latitude;
    final oldLongitude = profile.longitude;

    profile.zoneName = zoneName;
    profile.latitude = latitude;
    profile.longitude = longitude;
    notifyListeners();

    try {
      await ApiService.updateLocation(
        token: token,
        zoneName: zoneName,
        latitude: latitude,
        longitude: longitude,
      );
      await loadFromBackend();
      return null;
    } on ApiException catch (e) {
      profile.zoneName = oldZone;
      profile.latitude = oldLatitude;
      profile.longitude = oldLongitude;
      notifyListeners();
      return e.message;
    } catch (_) {
      profile.zoneName = oldZone;
      profile.latitude = oldLatitude;
      profile.longitude = oldLongitude;
      notifyListeners();
      return 'Failed to update location.';
    }
  }

  WeeklyPolicy? _parsePolicy(Map<String, dynamic>? data) {
    if (data == null) return null;
    final weekStartRaw = data['weekStart']?.toString();
    if (weekStartRaw == null) return null;

    return WeeklyPolicy(
      weekStart: DateTime.tryParse(weekStartRaw) ?? DateTime.now(),
      premiumPaid: (data['premiumPaid'] as num?)?.toDouble() ?? 40,
      zoneName: (data['zoneName'] ?? profile.zoneName).toString(),
      status: PolicyStatus.active,
    );
  }

  RiskFeedItem _parseRiskFeed(Map<String, dynamic> data) {
    return RiskFeedItem(
      label: (data['label'] ?? '').toString(),
      level: (data['level'] ?? '').toString(),
      icon: (data['icon'] ?? '').toString(),
    );
  }

  TriggerAlert _parseTriggerAlert(Map<String, dynamic> data) {
    final eventTypeRaw = (data['eventType'] ?? '').toString();
    final metrics = data['metrics'] as Map<String, dynamic>? ?? const {};
    final metricSummary = _buildMetricSummary(eventTypeRaw, metrics);

    return TriggerAlert(
      eventType: _parseEventType(eventTypeRaw),
      severity: _parseSeverity((data['severity'] ?? '').toString()),
      zoneStatus: _parseZoneStatus((data['zoneStatus'] ?? '').toString()),
      eventId: (data['eventId'] ?? '').toString(),
      dataSource: (data['dataSource'] ?? '').toString(),
      timestamp: DateTime.tryParse((data['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      metricSummary: metricSummary,
    );
  }

  String _buildMetricSummary(String eventType, Map<String, dynamic> metrics) {
    double? asDouble(String key) => (metrics[key] as num?)?.toDouble();

    switch (eventType.toLowerCase()) {
      case 'aqi':
        final usAqi = asDouble('usAqi');
        final pm25 = asDouble('pm25');
        if (usAqi == null && pm25 == null) return '';
        if (pm25 == null) return 'US AQI: ${usAqi!.toStringAsFixed(0)}';
        return 'US AQI: ${usAqi?.toStringAsFixed(0) ?? '-'} · PM2.5: ${pm25.toStringAsFixed(1)}';
      case 'heat':
        final temperature = asDouble('temperature');
        return temperature == null
            ? ''
            : 'Temperature: ${temperature.toStringAsFixed(1)} C';
      case 'flood':
        final rain = asDouble('rainMm');
        return rain == null ? '' : 'Rainfall: ${rain.toStringAsFixed(1)} mm';
      case 'traffic':
        final score = asDouble('trafficScore');
        return score == null
            ? ''
            : 'Mobility stress: ${(score * 100).toStringAsFixed(0)}%';
      default:
        return '';
    }
  }

  PayoutRecord _parsePayoutRecord(Map<String, dynamic> data) {
    return PayoutRecord(
      eventType: (data['eventType'] ?? '').toString(),
      eventDate: DateTime.tryParse((data['eventDate'] ?? '').toString()) ??
          DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: _parsePayoutStatus((data['status'] ?? '').toString()),
      triggerReason: (data['triggerReason'] ?? '').toString(),
      dataSource: (data['dataSource'] ?? '').toString(),
      eventId: (data['eventId'] ?? '').toString(),
    );
  }

  TriggerEventType _parseEventType(String value) {
    switch (value.toLowerCase()) {
      case 'flood':
        return TriggerEventType.flood;
      case 'heat':
      case 'heatwave':
        return TriggerEventType.heat;
      case 'aqi':
      case 'aqi spike':
        return TriggerEventType.aqi;
      case 'traffic':
      case 'traffic collapse':
        return TriggerEventType.traffic;
      default:
        return TriggerEventType.flood;
    }
  }

  EventSeverity _parseSeverity(String value) {
    switch (value.toLowerCase()) {
      case 'severe':
        return EventSeverity.severe;
      case 'catastrophic':
        return EventSeverity.catastrophic;
      default:
        return EventSeverity.normal;
    }
  }

  ZoneStatus _parseZoneStatus(String value) {
    switch (value.toLowerCase()) {
      case 'triggered':
        return ZoneStatus.triggered;
      case 'stable':
        return ZoneStatus.stable;
      default:
        return ZoneStatus.watchlist;
    }
  }

  PayoutStatus _parsePayoutStatus(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return PayoutStatus.paid;
      case 'pending':
        return PayoutStatus.pending;
      default:
        return PayoutStatus.rejected;
    }
  }

  PaymentSummary _parsePaymentSummary(Map<String, dynamic>? data) {
    if (data == null) return const PaymentSummary();

    return PaymentSummary(
      lastPayDate: DateTime.tryParse((data['lastPayDate'] ?? '').toString()),
      lastPayoutDate:
          DateTime.tryParse((data['lastPayoutDate'] ?? '').toString()),
      daysRemaining: (data['daysRemaining'] as num?)?.toInt() ?? 0,
      payAmount: (data['payAmount'] as num?)?.toDouble() ?? 0,
      payDue: (data['payDue'] as num?)?.toDouble() ?? 0,
      payDueDate: DateTime.tryParse((data['payDueDate'] ?? '').toString()),
    );
  }
}
