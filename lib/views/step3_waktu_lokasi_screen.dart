import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../controller/request_controller.dart';
import 'estimasi_harga_screen.dart';

class Step3WaktuLokasiScreen extends StatefulWidget {
  final RequestModel draft;
  const Step3WaktuLokasiScreen({super.key, required this.draft});

  @override
  State<Step3WaktuLokasiScreen> createState() =>
      _Step3WaktuLokasiScreenState();
}

class _Step3WaktuLokasiScreenState extends State<Step3WaktuLokasiScreen> {
  final RequestController _controller = RequestController();
  final _locationCtrl = TextEditingController(
      text: 'Perpustakaan Pusat Telkom University');

  String _selectedMode = 'Tatap Muka';
  late String _selectedDate;
  late String _selectedDateLabel;
  String _selectedTime = '15:00';

  late List<Map<String, String>> _dates;
  late List<String> _times;

  @override
  void initState() {
    super.initState();
    _dates = _controller.getAvailableDates();
    _times = _controller.getAvailableTimes();
    _selectedDate = _dates[0]['value']!;
    _selectedDateLabel = _dates[0]['sub']!;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      (_selectedMode == 'Online' || _locationCtrl.text.trim().isNotEmpty) &&
      _selectedDate.isNotEmpty &&
      _selectedTime.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waktu & Lokasi',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jadwal dan tempat perlu disetujui oleh helper',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Mode Layanan'),
                    const SizedBox(height: 10),
                    _buildModeSelector(),
                    if (_selectedMode == 'Tatap Muka') ...[
                      const SizedBox(height: 16),
                      _buildLabel('Lokasi Pertemuan'),
                      const SizedBox(height: 8),
                      _buildLocationField(),
                      const SizedBox(height: 6),
                      const Text(
                        'Lokasi bisa dinegosiasi dengan helper via chat setelah penawaran diterima.',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildLabel('Tanggal'),
                    const SizedBox(height: 10),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildLabel('Jam Mulai'),
                    const SizedBox(height: 10),
                    _buildTimeGrid(),
                    const SizedBox(height: 6),
                    const Text(
                      'Jam mulai bisa dinegosiasi dengan helper. Konfirmasi final dilakukan via chat.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      child: Column(
        children: [
          Row(
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat Permintaan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  Text('Langkah 3 dari 3',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(3),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: i < step
                  ? const Color(0xFF1BAB8A)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333)));
  }

  Widget _buildModeSelector() {
    return Row(
      children: ['Tatap Muka', 'Online'].map((mode) {
        final isSelected = _selectedMode == mode;
        final icon = mode == 'Tatap Muka'
            ? Icons.location_on_outlined
            : Icons.wifi_outlined;
        final sub = mode == 'Tatap Muka' ? 'Bertemu langsung' : 'Via chat/video';
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: mode == 'Tatap Muka' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FBF7) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1BAB8A)
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon,
                      size: 20,
                      color: isSelected
                          ? const Color(0xFF1BAB8A)
                          : const Color(0xFF888888)),
                  const SizedBox(height: 6),
                  Text(mode,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF1BAB8A)
                              : const Color(0xFF333333))),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationCtrl,
      style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_on_outlined,
            color: Color(0xFFAAAAAA), size: 20),
        hintText: 'Masukkan lokasi pertemuan',
        hintStyle:
            const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1BAB8A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: _dates.map((d) {
        final isSelected = _selectedDate == d['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedDate = d['value']!;
              _selectedDateLabel = d['sub']!;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: d != _dates.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1BAB8A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1BAB8A)
                      : const Color(0xFFE0E0E0),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF888888)),
                  const SizedBox(height: 4),
                  Text(d['label']!,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF333333))),
                  Text(d['sub']!,
                      style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white70
                              : const Color(0xFF888888))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: _times.map((t) {
        final isSelected = _selectedTime == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1BAB8A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1BAB8A)
                    : const Color(0xFFE0E0E0),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(t,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF444444))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3E8DA), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Jadwal',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F6E56))),
          const SizedBox(height: 8),
          _summaryRow(Icons.calendar_today_outlined, _selectedDateLabel),
          const SizedBox(height: 4),
          _summaryRow(
              Icons.access_time_rounded,
              '$_selectedTime WIB · ${widget.draft.duration}'),
          if (_selectedMode == 'Tatap Muka') ...[
            const SizedBox(height: 4),
            _summaryRow(Icons.location_on_outlined,
                _locationCtrl.text.trim()),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1BAB8A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF0F6E56))),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF555555)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final updated = widget.draft.copyWith(
                          mode: _selectedMode,
                          location: _selectedMode == 'Tatap Muka'
                              ? _locationCtrl.text.trim()
                              : 'Online',
                          date: _selectedDate,
                          time: _selectedTime,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EstimasiHargaScreen(draft: updated),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BAB8A),
                  disabledBackgroundColor: const Color(0xFFCCCCCC),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lihat Estimasi Harga',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}