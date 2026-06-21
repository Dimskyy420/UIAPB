import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng telkomUniversity = LatLng(-6.973970, 107.629799);

  static const String _userAgent = 'TasuruApp/1.0 (contact@tasuru.app)';

  static Future<LatLng?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}',
      );

      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final name = data['display_name'] as String?;
      return (name != null && name.trim().isNotEmpty) ? name : null;
    } catch (_) {
      return null;
    }
  }
  
  static Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
      );

      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return [];

      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((item) {
        final m = item as Map<String, dynamic>;
        return {
          'displayName': m['display_name'] as String? ?? '',
          'lat': double.tryParse(m['lat'] as String? ?? '0') ?? 0.0,
          'lon': double.tryParse(m['lon'] as String? ?? '0') ?? 0.0,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
