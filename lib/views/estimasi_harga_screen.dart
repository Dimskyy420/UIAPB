import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../controller/request_controller.dart';
import 'permintaan_terkirim_screen.dart';

class EstimasiHargaScreen extends StatefulWidget {
  final RequestModel draft;
  const EstimasiHargaScreen({super.key, required this.draft});

  @override
  State<EstimasiHargaScreen> createState() => _EstimasiHargaScreenState();
}

class _EstimasiHargaScreenState extends State<EstimasiHargaScreen> {
  final RequestController _controller = RequestController();
  bool _isLoading = false;
  late int _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.draft.totalEstimasi;
  }

  RequestModel get _currentDraft => widget.draft.copyWith(
        budget: _budget,
      );

  void _handlePublish() async {
    setState(() => _isLoading = true);
    final id = await _controller.submitRequest(_currentDraft);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (id != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PermintaanTerkirimScreen(request: _currentDraft),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal mengirim permintaan. Coba lagi.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _currentDraft;
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
                    _buildEstimasiCard(draft),
                    const SizedBox(height: 16),
                    _buildRincianCard(draft),
                    const SizedBox(height: 16),
                    _buildCurrentPriceCard(draft),
                    const SizedBox(height: 16),
                    _buildBudgetSlider(draft),
                  ],
                ),
              ),
            ),
            _buildPublishButton(),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Estimasi Harga',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
              Text('Berdasarkan detail permintaanmu',
                  style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
            ],
          ),
        ],
      ),
    );
  }


  // ─── Kalkulasi dinamis dari nilai slider ──────────────────────────────────
  int get _currentPlatformFee => (_budget * 0.10).round();
  int get _currentExtraFee => widget.draft.mode == 'Tatap Muka' ? 3000 : 0;
  int get _currentTotal => _budget + _currentPlatformFee + _currentExtraFee;

  Widget _buildCurrentPriceCard(RequestModel draft) {
    final diff = _currentTotal - draft.totalEstimasi;
    final isAbove = diff > 0;
    final isEqual = diff == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga Saat Ini',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEqual
                      ? const Color(0xFFE8F6F2)
                      : isAbove
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isEqual
                      ? 'Sesuai estimasi'
                      : isAbove
                          ? '+${_controller.formatRupiah(diff)} dari estimasi'
                          : '${_controller.formatRupiah(diff)} dari estimasi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isEqual
                        ? const Color(0xFF0F6E56)
                        : isAbove
                            ? const Color(0xFFE65100)
                            : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _currentPriceRow(
            'Budget Dasar',
            'Nilai yang kamu set',
            _controller.formatRupiah(_budget),
            null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          _currentPriceRow(
            'Platform Fee',
            '10% dari budget',
            _controller.formatRupiah(_currentPlatformFee),
            null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          _currentPriceRow(
            'Extra Fee',
            'Tatap muka – biaya operasional',
            _controller.formatRupiah(_currentExtraFee),
            draft.mode == 'Online' ? 'Offline' : null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bayar',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(
                _controller.formatRupiah(_currentTotal),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1BAB8A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _currentPriceRow(
      String title, String sub, String amount, String? badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF333333))),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF888888))),
                  ),
                ],
              ],
            ),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
        Text(amount,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildEstimasiCard(RequestModel draft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1BAB8A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Estimasi',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            _controller.formatRupiah(draft.totalEstimasi),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kisaran pasar: ${_controller.formatRupiah((draft.totalEstimasi * 0.8).round())} – ${_controller.formatRupiah((draft.totalEstimasi * 1.4).round())}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRincianCard(RequestModel draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Estimasi',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _rincianRow(
            'Biaya Layanan',
            '${draft.category} · ${draft.duration}',
            _controller.formatRupiah(draft.biayaLayanan),
            null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          _rincianRow(
            'Platform Fee',
            '10% dari biaya layanan',
            _controller.formatRupiah(draft.platformFee),
            null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          _rincianRow(
            'Extra Fee',
            'Tatap muka – biaya operasional',
            _controller.formatRupiah(draft.extraFee),
            draft.mode == 'Online' ? 'Offline' : null,
          ),
          const Divider(height: 16, color: Color(0xFFF0F0F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text(
                _controller.formatRupiah(draft.totalEstimasi),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1BAB8A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rincianRow(
      String title, String sub, String amount, String? badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF333333))),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF888888))),
                  ),
                ],
              ],
            ),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
        Text(amount,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildBudgetSlider(RequestModel draft) {
    // Slider max harus selalu >= totalEstimasi agar tidak crash
    final double sliderMax = (draft.totalEstimasi > 100000
            ? ((draft.totalEstimasi / 10000).ceil() * 10000).toDouble()
            : 100000.0);
    // Clamp budget agar tidak melebihi max slider
    final double safeValue = _budget.toDouble().clamp(5000.0, sliderMax);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Budget Maksimal',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFFAAAAAA)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _controller.formatRupiah(_budget),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1BAB8A),
            ),
          ),
          Slider(
            value: safeValue,
            min: 5000,
            max: sliderMax,
            activeColor: const Color(0xFF1BAB8A),
            inactiveColor: const Color(0xFFE0E0E0),
            onChanged: (val) => setState(() => _budget = val.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rp 5k',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFF888888))),
              Text(
                sliderMax >= 1000000
                    ? 'Rp ${(sliderMax / 1000000).toStringAsFixed(1)}jt'
                    : 'Rp ${(sliderMax / 1000).round()}k',
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ],
          ),
          if (_budget >= draft.totalEstimasi) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: Color(0xFF1BAB8A)),
                  SizedBox(width: 6),
                  Text('Budgetmu sesuai estimasi.',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF0F6E56))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAB8A),
                disabledBackgroundColor: const Color(0xFF1BAB8A).withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Publikasikan Permintaan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Helper akan mengirim penawaran setelah permintaan dipublikasi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}