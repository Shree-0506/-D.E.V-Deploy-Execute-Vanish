import 'dart:convert';
import 'package:http/http.dart' as http;

class ReverseGeocodingService {
  ReverseGeocodingService._();

  static Future<String?> reverseLookup({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&zoom=14&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'cashurance-demo/1.0',
        },
      );

      if (response.statusCode >= 400) return null;

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final address = payload['address'] as Map<String, dynamic>? ?? const {};

      final locality = (address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'] ??
              address['town'] ??
              address['village'] ??
              address['city'])
          ?.toString();
      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state_district'])
          ?.toString();

      if (locality != null && locality.isNotEmpty) {
        if (city != null && city.isNotEmpty && city != locality) {
          return '$locality, $city';
        }
        return locality;
      }

      if (city != null && city.isNotEmpty) return city;

      final display = payload['display_name']?.toString() ?? '';
      if (display.isEmpty) return null;
      return display.split(',').take(2).join(',').trim();
    } catch (_) {
      return null;
    }
  }
}
