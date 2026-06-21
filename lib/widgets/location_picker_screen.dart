import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/picked_location.dart';
import '../services/location_service.dart';

/// Layar pemilih lokasi berbasis peta OpenStreetMap.
///
/// Tap di peta → pindahkan pin + resolusi alamat (best-effort). Tombol "lokasi
/// saya" memusatkan ke posisi GPS. Konfirmasi mengembalikan [PickedLocation]
/// lewat `Navigator.pop`.
class LocationPickerScreen extends StatefulWidget {
  /// Lokasi yang sebelumnya dipilih — dipakai sebagai titik & alamat awal.
  final PickedLocation? initial;

  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _teal = Color(0xFF1BAB8A);

  // Fallback saat reverse-geocode gagal — koordinat tetap valid, hanya teksnya
  // yang tidak diketahui.
  static const _placeholder = 'Lokasi dipilih di peta';

  final MapController _mapController = MapController();

  late LatLng _picked;
  String _address = '';
  bool _resolving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial?.point ?? LocationService.telkomUniversity;
    _address = widget.initial?.address ?? '';
    // Belum ada alamat untuk titik awal → coba resolusi sekali.
    if (_address.isEmpty) _resolveAddress(_picked);
  }

  Future<void> _resolveAddress(LatLng point) async {
    setState(() => _resolving = true);
    final addr = await LocationService.reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      _address = addr ?? _placeholder;
      _resolving = false;
    });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() => _picked = point);
    _resolveAddress(point);
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak bisa mengakses lokasi. Aktifkan GPS & izinkan akses lokasi.',
          ),
        ),
      );
      return;
    }

    setState(() => _picked = pos);
    _mapController.move(pos, 16);
    _resolveAddress(pos);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        point: _picked,
        address: _address.trim().isEmpty ? _placeholder : _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _picked,
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
                    point: _picked,
                    width: 46,
                    height: 46,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on,
                        size: 46, color: _teal),
                  ),
                ],
              ),
              // Wajib dipertahankan: kebijakan OSM mensyaratkan atribusi.
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          _buildBackButton(),
          _buildLocateButton(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: Color(0xFF444444)),
          ),
        ),
      ),
    );
  }

  Widget _buildLocateButton() {
    // Ditempel di atas bottom sheet (bukan FAB default agar tidak tertutup).
    return Positioned(
      right: 16,
      bottom: 188,
      child: GestureDetector(
        onTap: _locating ? null : _locateMe,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _locating
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _teal),
                )
              : const Icon(Icons.my_location_rounded,
                  size: 22, color: _teal),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi Terpilih',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333)),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: _teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _resolving
                        ? const Text(
                            'Mencari alamat…',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF888888)),
                          )
                        : Text(
                            _address.isEmpty ? _placeholder : _address,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF222222)),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Konfirmasi Lokasi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
