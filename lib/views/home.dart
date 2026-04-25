import 'package:flutter/material.dart';
import '../controller/home_controller.dart';
import '../models/home_model.dart';
import '../widgets/custom_navigation.dart';
import 'step1_kategori.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();
  late final HomeModel? _user;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _user = _controller.getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
       onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const Step1KategoriScreen(),
    ),
  );
},
        backgroundColor: const Color(0xFF1BAB8A),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1BAB8A), Color(0xFF0F7A63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 14),
          const Text(
            'Butuh bantuan hari ini?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Sapaan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang 👋',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Halo, ${_user?.firstName ?? 'Pengguna'}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        Row(
          children: [
            // Notifikasi
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            // Foto profil Google
            _buildAvatar(),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final photoUrl = _user?.photoUrl;
    final initials = _user?.initials ?? 'U';

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.orange.shade400,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
      child: photoUrl == null
          ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFFAAAAAA)),
          hintText: 'Cari bantuan yang kamu butuhkan...',
          hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySection(),
          const SizedBox(height: 24),
          _buildRecentTaskSection(),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      {'icon': '📚', 'label': 'Akademik'},
      {'icon': '📋', 'label': 'Administrasi'},
      {'icon': '📦', 'label': 'Logistik'},
      {'icon': '🎉', 'label': 'Event'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Bantuan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories
              .map((cat) => _buildCategoryCard(
                    icon: cat['icon']!,
                    label: cat['label']!,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({required String icon, required String label}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Permintaan Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Lihat semua',
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          initials: 'AS',
          color: const Color(0xFF1BAB8A),
          name: 'Andi Saputra',
          title: 'Pendampingan Statistika Dasar',
          price: 'Rp 15.000 – 20.000',
          category: 'Akademik',
          isUrgent: true,
        ),
        _buildTaskCard(
          initials: 'MR',
          color: const Color(0xFF7C4DFF),
          name: 'Maya R.',
          title: 'Bantuan Desain Presentasi UAS',
          price: 'Rp 30.000 – 50.000',
          category: 'Akademik',
          isUrgent: false,
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required String initials,
    required Color color,
    required String name,
    required String title,
    required String price,
    required String category,
    required bool isUrgent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SEGERA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1BAB8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}