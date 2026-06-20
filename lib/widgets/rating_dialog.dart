import 'package:flutter/material.dart';
import '../controller/review_controller.dart';

/// Tampilkan dialog rating.
/// [toUid]     = UID user yang dinilai
/// [requestId] = ID request terkait
/// [toName]    = Nama user yang dinilai (untuk display)
/// [reviewerName] = Nama reviewer (current user)
Future<bool> showRatingDialog({
  required BuildContext context,
  required String toUid,
  required String requestId,
  required String toName,
  String reviewerName = '',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RatingDialog(
      toUid: toUid,
      requestId: requestId,
      toName: toName,
      reviewerName: reviewerName,
    ),
  );
  return result ?? false;
}

class _RatingDialog extends StatefulWidget {
  final String toUid;
  final String requestId;
  final String toName;
  final String reviewerName;

  const _RatingDialog({
    required this.toUid,
    required this.requestId,
    required this.toName,
    required this.reviewerName,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog>
    with SingleTickerProviderStateMixin {
  final ReviewController _controller = ReviewController();
  final TextEditingController _ulasanCtrl = TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;
  late AnimationController _starAnimController;

  static const _starLabels = [
    '',
    'Sangat Buruk 😞',
    'Buruk 😕',
    'Cukup 😐',
    'Baik 😊',
    'Luar Biasa 🌟',
  ];

  @override
  void initState() {
    super.initState();
    _starAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _ulasanCtrl.dispose();
    _starAnimController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih dulu bintang rating-nya!'),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final err = await _controller.submitReview(
      toUid: widget.toUid,
      requestId: widget.requestId,
      rating: _rating,
      ulasan: _ulasanCtrl.text.trim(),
      reviewerName: widget.reviewerName,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ikon header ─────────────────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1BAB8A), Color(0xFF0F7A63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),

            // ── Judul ────────────────────────────────────────────────────────
            const Text(
              'Beri Ulasan',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Bagaimana pengalamanmu dengan\n${widget.toName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF888888), height: 1.5),
            ),
            const SizedBox(height: 24),

            // ── Star rating ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final isActive = starIndex <= _rating;
                return GestureDetector(
                  onTap: () {
                    setState(() => _rating = starIndex);
                    _starAnimController
                      ..reset()
                      ..forward();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.elasticOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: isActive ? 1.15 : 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Icon(
                        isActive
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 42,
                        color: isActive
                            ? const Color(0xFFFFA726)
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // ── Label rating ─────────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _rating > 0 ? _starLabels[_rating] : 'Ketuk bintang untuk menilai',
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      _rating > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: _rating > 0
                      ? const Color(0xFF1BAB8A)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Kolom ulasan ─────────────────────────────────────────────────
            TextField(
              controller: _ulasanCtrl,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalamanmu (opsional)...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                counterStyle:
                    const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1BAB8A), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Tombol ───────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      backgroundColor: const Color(0xFF1BAB8A),
                      disabledBackgroundColor:
                          const Color(0xFF1BAB8A).withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kirim Ulasan',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
