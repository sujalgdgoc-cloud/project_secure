import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Service to fetch geographical location for transaction metadata.
class LocationService {
  /// Fetches transaction origin location matching the priority checklist.
  /// 1. Browser Geolocation / Device GPS
  /// 2. IP Geolocation
  /// 3. Fallback "unknown"
  static Future<Map<String, dynamic>> getTransactionLocation() async {
    double? latitude;
    double? longitude;
    String? city;
    String? state;
    String? country;
    String? ip;

    // ── STEP 1: Attempt to fetch Browser Geolocation / Device GPS ──
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (isServiceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
          latitude = position.latitude;
          longitude = position.longitude;
        }
      }
    } catch (e) {
      print('Geolocator failed/timed out: $e');
    }

    // ── STEP 2: Fetch IP address and details from ipapi.co (IP Geolocation) ──
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        ip = data['ip']?.toString();
        city = data['city']?.toString();
        state = data['region']?.toString();
        country = data['country_name']?.toString();

        // If GPS didn't provide coordinates, fall back to IP-based coordinates
        if (latitude == null || longitude == null) {
          final latVal = data['latitude'];
          final lonVal = data['longitude'];
          if (latVal is num) latitude = latVal.toDouble();
          if (lonVal is num) longitude = lonVal.toDouble();
        }
      }
    } catch (e) {
      print('IP Geolocation failed/timed out: $e');
    }

    // ── STEP 3: Return result or fallback status if completely unknown ──
    if (latitude == null && longitude == null && ip == null) {
      return {
        'status': 'unknown',
      };
    }

    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'city': city,
      'state': state,
      'country': country,
      'ip': ip,
    };
  }
}
