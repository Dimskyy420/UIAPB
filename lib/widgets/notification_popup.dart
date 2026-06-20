import 'package:flutter/material.dart';
import '../services/in_app_notification_service.dart';

/// Widget yang di-wrap di atas halaman manapun untuk mendengarkan
/// notifikasi baru dan menampilkan popup dialog secara otomatis.
class NotificationPopupListener extends StatefulWidget {
  final Widget child;
  const NotificationPopupListener({super.key, required this.child});

  @override
  State<NotificationPopupListener> createState() =>
      _NotificationPopupListenerState();
}

class _NotificationPopupListenerState
    extends State<NotificationPopupListener> {
  String? _lastShownNotifId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: InAppNotificationService.streamUnread(),
      builder: (context, snapshot) {
        // Jika ada data notif baru yang belum dibaca → tampilkan popup
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final doc = snapshot.data!.docs.first;
          final docId = doc.id;

          // Cegah popup muncul berkali-kali untuk notif yang sama
          if (_lastShownNotifId != docId) {
            _lastShownNotifId = docId;

            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? 'Notifikasi';
            final body = data['body'] as String? ?? '';
            final type = data['type'] as String? ?? 'general';

            // Tunda sedikit agar widget sudah selesai build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showPopup(context, docId: docId, title: title, body: body, type: type);
              }
            });
          }
        }

        return widget.child;
      },
    );
  }

  void _showPopup(
    BuildContext context, {
    required String docId,
    required String title,
    required String body,
    required String type,
  }) {
    // Tentukan warna & ikon berdasarkan tipe notifikasi
    final Color accentColor = type == 'bid_accepted'
        ? const Color(0xFF1BAB8A)   // Hijau → diterima
        : type == 'bid_rejected'
            ? const Color(0xFFFF8C00) // Oranye → ditolak
            : const Color(0xFF7C4DFF); // Ungu  → ada penawaran baru

    final IconData icon = type == 'bid_accepted'
        ? Icons.check_circle_rounded
        : type == 'bid_rejected'
            ? Icons.cancel_rounded
            : Icons.notifications_active_rounded;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'notif_popup',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Ikon animasi ─────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 36),
                  ),
                  const SizedBox(height: 20),

                  // ── Judul ────────────────────────────────────────────────
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Isi pesan ─────────────────────────────────────────────
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Tombol OK ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        // Tandai sebagai sudah dibaca
                        await InAppNotificationService.markAsRead(docId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Oke, Mengerti!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
