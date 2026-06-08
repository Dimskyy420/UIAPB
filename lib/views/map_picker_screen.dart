import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Hasil pemilihan lokasi dari MapPickerScreen
class PickedLocation {
  final LatLng latLng;
  final String address;
  const PickedLocation({required this.latLng, required this.address});
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLatLng;
  final String? initialAddress;

  const MapPickerScreen({
    super.key,
    this.initialLatLng,
    this.initialAddress,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Default: Telkom University (sesuai placeholder lokasi awal)
  static const LatLng _defaultCenter = LatLng(-6.973134, 107.630303);

  final MapController _mapController = MapController();
  late LatLng _pinned;
  String _address = '';
  bool _isGeocoding = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _pinned = widget.initialLatLng ?? _defaultCenter;
    _address = widget.initialAddress ?? '';
    _bootstrapPosition();
  }

  // ─── Saat pertama buka: pakai initial → device GPS → default ────────────
  Future<void> _bootstrapPosition() async {
    if (widget.initialLatLng != null) {
      // Sudah ada pin sebelumnya, langsung pakai
      if (_address.isEmpty) await _reverseGeocode(_pinned);
      if (mounted) setState(() => _isLoadingInitial = false);
      return;
    }

    final pos = await _tryGetCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      _pinned = LatLng(pos.latitude, pos.longitude);
      _animateCameraTo(_pinned);
      await _reverseGeocode(_pinned);
    } else {
      // Pakai default center, reverse-geocode juga
      await _reverseGeocode(_pinned);
    }

    if (mounted) setState(() => _isLoadingInitial = false);
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _animateCameraTo(LatLng target) {
    _mapController.move(target, 16);
  }

  // ─── Reverse geocode: LatLng → alamat ───────────────────────────────────
  Future<void> _reverseGeocode(LatLng latLng) async {
    if (mounted) setState(() => _isGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.street ?? '').isNotEmpty) p.street!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.subAdministrativeArea ?? '').isNotEmpty)
            p.subAdministrativeArea!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
        ];
        final addr = parts.join(', ');
        if (mounted) {
          setState(() => _address = addr.isNotEmpty
              ? addr
              : '${latLng.latitude.toStringAsFixed(5)}, '
                  '${latLng.longitude.toStringAsFixed(5)}');
        }
      } else {
        if (mounted) {
          setState(() => _address =
              '${latLng.latitude.toStringAsFixed(5)}, '
              '${latLng.longitude.toStringAsFixed(5)}');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address =
            '${latLng.latitude.toStringAsFixed(5)}, '
            '${latLng.longitude.toStringAsFixed(5)}');
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() => _pinned = position);
    _reverseGeocode(position);
  }

  Future<void> _onMyLocationPressed() async {
    final pos = await _tryGetCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak bisa mendapatkan lokasi saat ini.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final target = LatLng(pos.latitude, pos.longitude);
    setState(() => _pinned = target);
    _animateCameraTo(target);
    await _reverseGeocode(target);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(latLng: _pinned, address: _address),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pinned,
                      initialZoom: 16,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.tasuru_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pinned,
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1BAB8A),
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_isLoadingInitial)
                    Container(
                      color: Colors.black.withOpacity(0.05),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1BAB8A),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      heroTag: 'mapPickerMyLocation',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1BAB8A),
                      elevation: 2,
                      onPressed: _onMyLocationPressed,
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 18, color: Color(0xFF444444)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Lokasi',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Text('Ketuk peta untuk menandai titik',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF888888))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 20, color: Color(0xFF1BAB8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alamat terpilih',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    _isGeocoding
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1BAB8A),
                              ),
                            ),
                          )
                        : Text(
                            _address.isEmpty
                                ? 'Ketuk peta untuk memilih lokasi'
                                : _address,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF222222),
                                fontWeight: FontWeight.w500),
                          ),
                    const SizedBox(height: 2),
                    Text(
                      '${_pinned.latitude.toStringAsFixed(5)}, '
                      '${_pinned.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_isGeocoding || _address.isEmpty) ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAB8A),
                disabledBackgroundColor: const Color(0xFFCCCCCC),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Gunakan Lokasi Ini',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
