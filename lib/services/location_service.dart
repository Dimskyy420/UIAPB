import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Layanan lokasi perangkat + reverse-geocoding via OpenStreetMap.
///
/// Tidak menyentuh Firestore. Dipakai oleh LocationPickerScreen.
class LocationService {
  /// Centroid kampus Telkom University (bukan gedung tertentu). Dipakai sebagai
  /// titik awal peta ketika user belum pernah memilih lokasi sama sekali.
  static const LatLng telkomUniversity = LatLng(-6.973970, 107.629799);

  // Nominatim & tile OSM memblokir request tanpa User-Agent yang valid.
  // TODO(rilis): ganti dengan kontak asli (email/website) sebelum rilis —
  // jangan biarkan placeholder generik ini, request bisa diblokir.
  static const String _userAgent = 'TasuruApp/1.0 (contact@tasuru.app)';

  /// Ambil posisi perangkat saat ini.
  ///
  /// Mengembalikan `null` bila layanan lokasi mati atau izin ditolak — bukan
  /// melempar exception. Pemanggil (tombol "lokasi saya") harus menangani null
  /// dengan menampilkan pesan, bukan diam.
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

  /// Resolusi koordinat menjadi alamat lewat endpoint `/reverse` Nominatim.
  ///
  /// Best-effort: mengembalikan `null` saat gagal (jaringan, rate-limit, dsb).
  /// Pemanggil memakai string placeholder sebagai fallback — yang benar-benar
  /// disimpan adalah koordinatnya, bukan teks alamat ini.
  ///
  /// Catatan: Nominatim dibatasi 1 request/detik. Jangan panggil dalam loop.
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
}
