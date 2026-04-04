import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();

  static const String _defaultBaseUrl = 'http://139.59.12.72:3000';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static Future<void> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode >= 400) {
      throw ApiException('Backend is unavailable at $baseUrl');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required String platform,
    required String upiId,
    String? dob,
    String? address,
    String? pincode,
    String? platformWorkerId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'platform': platform,
        'upi_id': upiId,
        'dob': dob,
        'address': address,
        'pincode': pincode,
        'platform_worker_id': platformWorkerId,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Registration failed.');
    }
    return payload;
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(payload['message']?.toString() ?? 'Login failed.');
    }
    return payload['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchState(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/app/state'),
      headers: _authHeaders(token),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to load app state.');
    }
    return payload['data'] as Map<String, dynamic>;
  }

  static Future<void> confirmZone({
    required String token,
    required String zoneName,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/app/zone/confirm'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'zoneName': zoneName,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to confirm zone.');
    }
  }

  static Future<void> purchasePolicy({
    required String token,
    required double premiumPaid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/app/policy/purchase'),
      headers: _authHeaders(token),
      body: jsonEncode({'premiumPaid': premiumPaid}),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to purchase policy.');
    }
  }

  static Future<void> setOnlineIntent({
    required String token,
    required bool onlineToday,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/app/intent'),
      headers: _authHeaders(token),
      body: jsonEncode({'onlineToday': onlineToday}),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to save online status.');
    }
  }

  static Future<void> updateProfile({
    required String token,
    required String fullName,
    required String platform,
    required String upiId,
    String? zoneName,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/app/profile'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'fullName': fullName,
        'platform': platform,
        'upiId': upiId,
        'zoneName': zoneName,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to update profile.');
    }
  }

  static Future<void> updateLocation({
    required String token,
    required String zoneName,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/v1/app/location'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'zoneName': zoneName,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(
          payload['message']?.toString() ?? 'Failed to update location.');
    }
  }

  static Future<void> updateNotificationPreferences({
    required String token,
    required bool eventAlerts,
    required bool weeklyReminders,
    required bool payoutNotifs,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/app/notifications/preferences'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'eventAlerts': eventAlerts,
        'weeklyReminders': weeklyReminders,
        'payoutNotifs': payoutNotifs,
      }),
    );

    final payload = _decode(response.body);
    if (response.statusCode >= 400 || payload['success'] != true) {
      throw ApiException(payload['message']?.toString() ??
          'Failed to update notification preferences.');
    }
  }

  static Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
