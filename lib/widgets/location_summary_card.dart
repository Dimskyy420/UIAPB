import 'package:flutter/material.dart';
import '../models/picked_location.dart';
import 'location_picker_screen.dart';

/// Kartu pemilih lokasi untuk step-3 "Lokasi Pertemuan".
///
/// Selalu menampilkan tile "Pilih lokasi di peta". Setelah ada lokasi terpilih,
/// menampilkan tile kedua berisi alamat hasil resolusi. Tap salah satu tile
/// membuka [LocationPickerScreen] dan menunggu [PickedLocation].
class LocationSummaryCard extends StatelessWidget {
  static const _teal = Color(0xFF1BAB8A);

  /// Lokasi yang sedang terpilih (null bila belum ada).
  final PickedLocation? value;

  /// Dipanggil ketika user mengonfirmasi lokasi baru dari peta.
  final ValueChanged<PickedLocation> onPicked;

  const LocationSummaryCard({
    super.key,
    required this.value,
    required this.onPicked,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initial: value),
      ),
    );
    if (result != null) onPicked(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tile selalu terlihat — buka peta.
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined,
                      size: 20, color: _teal),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pilih lokasi di peta',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222))),
                      SizedBox(height: 2),
                      Text('Tandai titik pertemuan di peta',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF999999))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFAAAAAA)),
              ],
            ),
          ),
        ),

        // Tile alamat — hanya muncul setelah ada lokasi terpilih.
        if (value != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openPicker(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF7),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFFC3E8DA), width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 18, color: _teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value!.address,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0F6E56)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Ubah',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _teal)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
