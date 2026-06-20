import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/auth_controller.dart';
import '../controller/profile_controller.dart';
import '../models/home_model.dart';
import 'auth_screen.dart';

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
  String _university = '';
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUniversity();
    _loadRating();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFE74C3C), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Keluar dari akun?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A))),
              const SizedBox(height: 8),
              const Text(
                'Kamu harus masuk kembali\nuntuk menggunakan TASURU.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF888888), height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFE74C3C),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keluar',
                          style: TextStyle(
                              fontSize: 13,
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
    await _authController.logout(); // FCM token dihapus di sini
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false, // Hapus semua route → back button tidak bisa kembali
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final photoUrl = user?.photoUrl;
    final initials = user?.initials ?? 'U';
    final name = user?.displayName ?? 'Pengguna';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(photoUrl, initials, name, email),
            const SizedBox(height: 16),

            // ── Statistik ─────────────────────────────────────────────────
            _buildStatsSection(),
            const SizedBox(height: 14),

            // ── Info Akun ─────────────────────────────────────────────────
            _buildSection(
              title: 'Informasi Akun',
              children: [
                _buildInfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Nama',
                    value: name),
                _divider(),
                _buildInfoTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: email),
                if (_university.isNotEmpty) ...[
                  _divider(),
                  _buildInfoTile(
                      icon: Icons.menu_book_outlined,
                      label: 'Universitas',
                      value: _university),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ── Pengaturan ────────────────────────────────────────────────
            _buildSection(
              title: 'Pengaturan',
              children: [
                _buildMenuTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifikasi',
                    onTap: () {}),
                _divider(),
                _buildMenuTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privasi & Keamanan',
                    onTap: () {}),
                _divider(),
                _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Bantuan & Dukungan',
                    onTap: () {}),
              ],
            ),
            const SizedBox(height: 14),

            // ── Ulasan ────────────────────────────────────────────────────
            _buildReviewsSection(),
            const SizedBox(height: 14),

            // ── Tombol Logout ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    disabledBackgroundColor:
                        const Color(0xFFE74C3C).withOpacity(0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      String? photoUrl, String initials, String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1BAB8A), Color(0xFF0F7A63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: Colors.orange.shade400,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26))
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(email,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  // ── Statistik ──────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _profileController.streamStats(),
        builder: (context, snap) {
          final stats = snap.data ?? {};
          final taskSelesai = stats['totalTaskSelesai'] ?? 0;
          final earned = stats['totalEarned'] ?? 0;
          final ratingStr = _avgRating > 0
              ? _avgRating.toStringAsFixed(1)
              : '-';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
            ),
            child: Row(
              children: [
                _StatItem(
                    icon: '✅',
                    label: 'Task Selesai',
                    value: taskSelesai.toString()),
                _verticalDivider(),
                _StatItem(
                    icon: '⭐',
                    label: 'Rating',
                    value: ratingStr),
                _verticalDivider(),
                _StatItem(
                    icon: '💰',
                    label: 'Total Earned',
                    value: earned > 0
                        ? _profileController.formatRupiah(earned)
                        : '-'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _verticalDivider() => Container(
        height: 40,
        width: 1,
        color: const Color(0xFFF0F0F0),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Ulasan ─────────────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Ulasan Diterima',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 0.3),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _profileController.streamMyReviews(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1BAB8A), strokeWidth: 2),
                  ),
                );
              }

              if (snap.hasError || !snap.hasData || snap.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFEEEEEE), width: 0.8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.star_outline_rounded,
                          size: 36, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 8),
                      Text('Belum ada ulasan',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF888888))),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEEEEEE), width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFA726),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '"$comment"',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                                fontStyle: FontStyle.italic,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────────

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF888888),
                    letterSpacing: 0.3)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon,
      required String label,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF9F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1BAB8A), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '-' : value,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF666666), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 0.8, indent: 64, color: Color(0xFFF0F0F0));
}

// ── Stat Item Widget ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String icon, label, value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}
