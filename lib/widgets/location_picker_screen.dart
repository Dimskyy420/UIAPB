import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/picked_location.dart';
import '../services/location_service.dart';


class LocationPickerScreen extends StatefulWidget {
  final PickedLocation? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _teal = Color(0xFF1BAB8A);
  static const _placeholder = 'Lokasi dipilih di peta';

  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late LatLng _picked;
  String _address = '';
  bool _resolving = false;
  bool _locating = false;

  // Autocomplete state
  List<Map<String, dynamic>> _suggestions = [];
  bool _searching = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial?.point ?? LocationService.telkomUniversity;
    _address = widget.initial?.address ?? '';
    if (_address.isEmpty) _resolveAddress(_picked);

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
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
    _searchFocus.unfocus();
    setState(() {
      _picked = point;
      _showSuggestions = false;
    });
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

    setState(() {
      _picked = pos;
      _showSuggestions = false;
    });
    _mapController.move(pos, 16);
    _resolveAddress(pos);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final results = await LocationService.searchAddress(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
        _showSuggestions = results.isNotEmpty;
      });
    });
  }

  void _onSuggestionTap(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'] as double;
    final lon = suggestion['lon'] as double;
    final name = suggestion['displayName'] as String;
    final point = LatLng(lat, lon);

    _searchCtrl.text = name;
    _searchFocus.unfocus();

    setState(() {
      _picked = point;
      _address = name;
      _showSuggestions = false;
      _suggestions = [];
    });

    _mapController.move(point, 16);
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
          // ── Peta ──────────────────────────────────────────────────────────
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
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // ── Search bar + suggestions ───────────────────────────────────
          _buildSearchBar(),

          // ── Tombol kembali ────────────────────────────────────────────
          _buildBackButton(),

          // ── Tombol lokasi saya ────────────────────────────────────────
          _buildLocateButton(),

          // ── Bottom sheet konfirmasi ───────────────────────────────────
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cari alamat atau tempat...',
                  hintStyle: const TextStyle(
                      color: Color(0xFFBBBBBB), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: Color(0xFF888888)),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _teal),
                          ),
                        )
                      : _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Color(0xFF888888)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _suggestions = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Dropdown suggestions
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 16, color: Color(0xFFF0F0F0)),
                    itemBuilder: (_, i) {
                      final s = _suggestions[i];
                      final name = s['displayName'] as String;
                      return InkWell(
                        onTap: () => _onSuggestionTap(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined,
                                  size: 16, color: _teal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF333333)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
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
