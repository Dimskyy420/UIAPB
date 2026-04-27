import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../controller/home_controller.dart';
import '../controller/request_controller.dart';
import '../models/home_model.dart';
import '../models/request_model.dart';
import '../widgets/custom_navigation.dart';
import 'search_tasks_screen.dart';
import 'riwayat_tugas_screen.dart';
import 'chat_log_screen.dart';
import 'step1_kategori.dart';
import 'profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();
  final RequestController _requestController = RequestController();
  late final HomeModel? _user;
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _user = _controller.getUser();
    _pages = [
      _HomeContent(
        user: _user,
        requestController: _requestController,
        onAddRequest: _openAddRequest,
        onSearchTap: _goToSearchScreen,
      ),
      const RiwayatTugasScreen(),
      const ChatLogScreen(),
      ProfileScreen(user: _user),
    ];
  }

  void _openAddRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Step1KategoriScreen()),
    );
  }

  void _goToSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchAvailableTasksScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _openAddRequest,
              backgroundColor: const Color(0xFF1BAB8A),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─── Placeholder pages ────────────────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded,
              size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          Text(
            'Halaman $label',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Segera hadir',
            style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }
}

// ─── Home Content (tab 0) ─────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final HomeModel? user;
  final RequestController requestController;
  final VoidCallback onAddRequest;
  final VoidCallback onSearchTap;

  const _HomeContent({
    required this.user,
    required this.requestController,
    required this.onAddRequest,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang 👋',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Halo, ${user?.firstName ?? 'Pengguna'}!',
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
            _buildAvatar(),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final photoUrl = user?.photoUrl;
    final initials = user?.initials ?? 'U';
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

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFFAAAAAA)),
            SizedBox(width: 10),
            Text(
              'Cari bantuan yang kamu butuhkan...',
              style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySection(),
          const SizedBox(height: 20),
          _buildSearchTaskBanner(context),
          const SizedBox(height: 24),
          _buildRecentTaskSection(context),
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

  Widget _buildSearchTaskBanner(BuildContext context) {
    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1BAB8A), Color(0xFF0F7A63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.work_outline_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cari Tugas Tersedia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Temukan permintaan yang sesuai keahlianmu',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTaskSection(BuildContext context) {
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
            GestureDetector(
              onTap: onSearchTap,
              child: Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                      color: Color(0xFF1BAB8A), strokeWidth: 2),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 36, color: Color(0xFFCCCCCC)),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada permintaan',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              );
            }

            final requests = snapshot.data!.docs
                .map((doc) => RequestModel.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            return Column(
              children: requests
                  .map((r) => _buildTaskCard(r, requestController))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(RequestModel request, RequestController ctrl) {
    final colors = [
      const Color(0xFF1BAB8A),
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6B35),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
    ];
    final colorIndex =
        (request.title.isNotEmpty ? request.title.codeUnitAt(0) : 0) %
            colors.length;
    final avatarColor = colors[colorIndex];
    final initials = request.title.isNotEmpty
        ? request.title.trim().split(' ').take(2).map((w) => w[0]).join()
        : '??';

    final bool isNew = request.createdAt != null &&
        DateTime.now().difference(request.createdAt!).inHours < 3;

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      request.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BARU',
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
                  request.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  ctrl.formatRupiah(request.budget),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1BAB8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC)),
        ],
      ),
    );
  }
}