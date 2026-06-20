import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/auth_controller.dart';
import '../controller/profile_controller.dart';
import '../models/home_model.dart';
import 'auth_screen.dart';
import 'notification_screen.dart';

class ProfileScreen extends StatefulWidget {
  final HomeModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = AuthController();
  final ProfileController _profileController = ProfileController();

  bool _isLoggingOut = false;
  bool _isUploadingPhoto = false;
  String _university = '';
  double _avgRating = 0.0;
  String? _currentPhotoUrl; // override lokal setelah upload

  @override
  void initState() {
    super.initState();
    _loadUniversity();
    _loadRating();
    _currentPhotoUrl = widget.user?.photoUrl;
  }

  Future<void> _loadUniversity() async {
    final uid = _authController.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _university = doc.data()?['university'] ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadRating() async {
    final rating = await _profileController.getAverageRating();
    if (mounted) setState(() => _avgRating = rating);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFE74C3C), size: 30),
              ),
              const SizedBox(height: 18),
              const Text('Keluar dari akun?',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              const Text(
                'Kamu harus masuk kembali\nuntuk menggunakan TASURU.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF888888), height: 1.6),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: const Color(0xFFE74C3C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Keluar',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    await _authController.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  // ── Pilih & Upload Foto ────────────────────────────────────────────────────

  // ── Update Foto via URL ────────────────────────────────────────────────────

  void _showPhotoUrlDialog() {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Ubah Foto Profil',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan URL/Link gambar untuk foto profilmu:',
                style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                hintText: 'https://contoh.com/foto.jpg',
                hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isEmpty) return;
              Navigator.pop(ctx);
              
              setState(() => _isUploadingPhoto = true);
              final success = await _profileController.updateProfilePhotoUrl(newUrl);
              
              if (mounted) {
                setState(() {
                  _isUploadingPhoto = false;
                  if (success) _currentPhotoUrl = newUrl;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Foto profil berhasil diperbarui! 🎉' : 'Gagal mengubah foto. Coba lagi.'),
                    backgroundColor: success ? const Color(0xFF1BAB8A) : const Color(0xFFE74C3C),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1BAB8A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photoUrl = _currentPhotoUrl ?? user?.photoUrl;
    final initials = user?.initials ?? 'U';
    final name = user?.displayName ?? 'Pengguna';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero Header ─────────────────────────────────────────────────
            _buildHeader(photoUrl, initials, name, email),

            // ── Stats Row ───────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsSection(),
              ),
            ),

            // Compensate the upward shift
            const SizedBox(height: 0),

            // ── Info Akun ───────────────────────────────────────────────────
            _buildSectionLabel('Informasi Akun'),
            _buildSection(
              children: [
                _buildInfoTile(
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF7C4DFF),
                    iconBg: const Color(0xFFF0EBFF),
                    label: 'Nama',
                    value: name),
                _divider(),
                _buildInfoTile(
                    icon: Icons.mail_rounded,
                    iconColor: const Color(0xFF2196F3),
                    iconBg: const Color(0xFFE8F4FD),
                    label: 'Email',
                    value: email),
                if (_university.isNotEmpty) ...[
                  _divider(),
                  _buildInfoTile(
                      icon: Icons.school_rounded,
                      iconColor: const Color(0xFF1BAB8A),
                      iconBg: const Color(0xFFE8F7F4),
                      label: 'Universitas',
                      value: _university),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // ── Pengaturan ──────────────────────────────────────────────────
            _buildSectionLabel('Pengaturan'),
            _buildSection(
              children: [
                _buildMenuTile(
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFFFF9800),
                    iconBg: const Color(0xFFFFF3E0),
                    label: 'Notifikasi',
                    subtitle: 'Atur preferensi notifikasi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    }),
                _divider(),
                _buildMenuTile(
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFFEF5350),
                    iconBg: const Color(0xFFFFF0F0),
                    label: 'Privasi & Keamanan',
                    subtitle: 'Kelola keamanan akunmu',
                    onTap: () {}),
                _divider(),
                _buildMenuTile(
                    icon: Icons.help_rounded,
                    iconColor: const Color(0xFF1BAB8A),
                    iconBg: const Color(0xFFE8F7F4),
                    label: 'Bantuan & Dukungan',
                    subtitle: 'FAQ dan hubungi kami',
                    onTap: () {}),
              ],
            ),
            const SizedBox(height: 8),

            // ── Ulasan ──────────────────────────────────────────────────────
            _buildSectionLabel('Ulasan Diterima'),
            _buildReviewsSection(),
            const SizedBox(height: 20),

            // ── Tombol Logout ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 18),
                  label: Text(
                    _isLoggingOut ? 'Keluar...' : 'Keluar dari Akun',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    disabledBackgroundColor:
                        const Color(0xFFE74C3C).withOpacity(0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(
      String? photoUrl, String initials, String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1BAB8A), Color(0xFF0D6E55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploadingPhoto ? null : _showPhotoUrlDialog,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.orange.shade400,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30))
                            : null,
                      ),
                      if (_isUploadingPhoto)
                        Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x88000000),
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isUploadingPhoto)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF1BAB8A), width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: Color(0xFF1BAB8A)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Statistik ────────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _profileController.streamStats(),
      builder: (context, snap) {
        final stats = snap.data ?? {};
        final taskSelesai = stats['totalTaskSelesai'] ?? 0;
        final earned = stats['totalEarned'] ?? 0;
        final ratingStr = _avgRating > 0
            ? _avgRating.toStringAsFixed(1)
            : '-';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              _StatCard(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF1BAB8A),
                iconBg: const Color(0xFFE8F7F4),
                label: 'Selesai',
                value: taskSelesai.toString(),
              ),
              _verticalDivider(),
              _StatCard(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFA726),
                iconBg: const Color(0xFFFFF8E1),
                label: 'Rating',
                value: ratingStr,
              ),
              _verticalDivider(),
              _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF7C4DFF),
                iconBg: const Color(0xFFF0EBFF),
                label: 'Earned',
                value: earned > 0
                    ? _profileController.formatRupiah(earned)
                    : '-',
                smallValue: earned > 0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _verticalDivider() => Container(
        height: 48,
        width: 1,
        color: const Color(0xFFF0F0F0),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Ulasan ──────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: _profileController.streamMyReviews(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1BAB8A), strokeWidth: 2),
              ),
            );
          }

          if (snap.hasError || !snap.hasData || snap.data!.docs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.star_outline_rounded,
                      size: 44, color: Color(0xFFDDDDDD)),
                  SizedBox(height: 10),
                  Text('Belum ada ulasan',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF888888))),
                  SizedBox(height: 4),
                  Text('Ulasan akan muncul setelah menyelesaikan tugas',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;
          return Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rating = (data['rating'] as num).toDouble();
              final comment = data['comment'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFFFA726),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFFFFA726)),
                          ),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"$comment"',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            fontStyle: FontStyle.italic,
                            height: 1.5),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ── Shared ───────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFFAAAAAA),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600)),
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

  Widget _divider() => const Divider(
      height: 1, thickness: 0.8, indent: 70, color: Color(0xFFF5F5F5));
}

// ── Stat Card Widget ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: smallValue ? 12 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Photo Source Button Widget ────────────────────────────────────────────────

class _PhotoSourceButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceButton({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
