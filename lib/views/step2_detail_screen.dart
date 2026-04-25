import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import 'step3_waktu_lokasi_screen.dart';

class Step2DetailScreen extends StatefulWidget {
  final RequestModel draft;
  const Step2DetailScreen({super.key, required this.draft});

  @override
  State<Step2DetailScreen> createState() => _Step2DetailScreenState();
}

class _Step2DetailScreenState extends State<Step2DetailScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedDuration = '1-2 jam';

  final List<String> _durations = [
    '< 1 jam', '1-2 jam', '2-4 jam', '1 hari', '2-3 hari'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty;

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
                      'Detail Permintaan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jelaskan kebutuhanmu agar helper bisa memahami',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Judul Permintaan'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleCtrl,
                      hint: 'Contoh: Pendampingan belajar Statistika Dasar',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Deskripsi'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descCtrl,
                      hint:
                          'Jelaskan secara detail apa yang kamu butuhkan...',
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Estimasi Durasi'),
                    const SizedBox(height: 12),
                    _buildDurationChips(),
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
                  Text(
                    'Buat Permintaan',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A)),
                  ),
                  Text('Langkah 2 dari 3',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(2),
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
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

  Widget _buildDurationChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _durations.map((d) {
        final isSelected = _selectedDuration == d;
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1BAB8A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1BAB8A)
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Text(
              d,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF555555),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Row(
        children: [
          // Tombol back
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
          // Tombol lanjut
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isValid
                    ? () {
                        final updated = widget.draft.copyWith(
                          title: _titleCtrl.text.trim(),
                          description: _descCtrl.text.trim(),
                          duration: _selectedDuration,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Step3WaktuLokasiScreen(draft: updated),
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
                    Text('Lanjut',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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