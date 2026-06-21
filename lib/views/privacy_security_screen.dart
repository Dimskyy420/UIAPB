import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/auth_controller.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1BAB8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privasi & Keamanan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Keamanan Akun ──────────────────────────────────────────────────
          const _SectionHeader(label: 'Keamanan akun'),
          _buildCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_reset_rounded,
                label: 'Ganti Kata Sandi',
                subtitle: 'Kirim email link reset kata sandi',
                onTap: () => _sendResetEmail(context),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Privasi ────────────────────────────────────────────────────────
          const _SectionHeader(label: 'Privasi'),
          _buildCard(
            children: [
              _SettingsTile(
                icon: Icons.visibility_off_rounded,
                label: 'Data Pribadi',
                subtitle: 'Kelola informasi yang kamu bagikan',
                onTap: () => _showInfoDialog(
                  context,
                  title: 'Data Pribadi',
                  message:
                      'Kami hanya menyimpan informasi yang kamu berikan saat mendaftar '
                      '(nama, email, universitas, dan foto profil). Data ini tidak pernah '
                      'dijual atau dibagikan ke pihak ketiga.',
                ),
              ),
              const Divider(height: 1, indent: 70, color: Color(0xFFF5F5F5)),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                label: 'Hapus Akun',
                subtitle: 'Hapus akun dan semua datamu secara permanen',
                labelColor: const Color(0xFFE74C3C),
                onTap: () => _showDeleteConfirm(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  static Future<void> _sendResetEmail(BuildContext context) async {
    final email = AuthController().currentUser?.email;
    if (email == null || email.isEmpty) {
      _showSnackBar(context, 'Email tidak ditemukan', isError: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        _showSnackBar(context, 'Link reset dikirim ke $email ✉️');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Gagal mengirim email reset', isError: true);
      }
    }
  }

  static void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF555555), height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti',
                style: TextStyle(color: Color(0xFF1BAB8A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Akun?',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE74C3C))),
        content: const Text(
          'Semua data kamu (profil, riwayat tugas, ulasan) akan dihapus secara permanen '
          'dan tidak bisa dipulihkan.',
          style: TextStyle(
              fontSize: 13, color: Color(0xFF555555), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hubungi Support',
                style: TextStyle(
                    color: Color(0xFFE74C3C), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFE74C3C) : const Color(0xFF1BAB8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1BAB8A), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? const Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFDDDDDD), size: 22),
          ],
        ),
      ),
    );
  }
}
