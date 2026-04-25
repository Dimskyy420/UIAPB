import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../controller/request_controller.dart';

class SearchAvailableTasksScreen extends StatefulWidget {
  const SearchAvailableTasksScreen({super.key});

  @override
  State<SearchAvailableTasksScreen> createState() =>
      _SearchAvailableTasksScreenState();
}

class _SearchAvailableTasksScreenState
    extends State<SearchAvailableTasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RequestController _requestController = RequestController();

  String _query = '';
  String _selectedCategory = 'Semua';

  static const List<String> _categories = [
    'Semua',
    'Akademik',
    'Administrasi',
    'Logistik',
    'Event',
  ];

  static const Map<String, String> _categoryIcons = {
    'Semua': '🔍',
    'Akademik': '📚',
    'Administrasi': '📋',
    'Logistik': '📦',
    'Event': '🎉',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter a list of requests based on query & selected category
  List<RequestModel> _filter(List<RequestModel> all) {
    final q = _query.toLowerCase();
    return all.where((r) {
      final matchCategory =
          _selectedCategory == 'Semua' || r.category == _selectedCategory;
      final matchQuery = q.isEmpty ||
          r.title.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      return matchCategory && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
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
          const Text(
            'Cari Tugas Tersedia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan permintaan yang sesuai keahlianmu',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Color(0xFFAAAAAA)),
          hintText: 'Cari berdasarkan judul, kategori, deskripsi...',
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          border: InputBorder.none,
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      size: 18, color: Color(0xFFAAAAAA)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ─── Category Filter ──────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1BAB8A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1BAB8A)
                      : const Color(0xFFDDDDDD),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _categoryIcons[cat] ?? '📌',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Task List (real-time stream) ─────────────────────────────────────────

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1BAB8A)),
          );
        }

        // Error
        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat data',
            subtitle: 'Periksa koneksi internet kamu',
            iconColor: Colors.redAccent,
          );
        }

        // Parse docs
        final docs = snapshot.data?.docs ?? [];
        final allRequests = docs
            .map((doc) => RequestModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        // Apply search + category filter
        final filtered = _filter(allRequests);

        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: _query.isNotEmpty || _selectedCategory != 'Semua'
                ? 'Tidak ada hasil'
                : 'Belum ada tugas tersedia',
            subtitle: _query.isNotEmpty || _selectedCategory != 'Semua'
                ? 'Coba kata kunci atau kategori lain'
                : 'Jadilah yang pertama memposting permintaan!',
          );
        }

        return Column(
          children: [
            // Result count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} tugas ditemukan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) =>
                    _buildTaskCard(filtered[i], _requestController),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Task Card ────────────────────────────────────────────────────────────

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

    final bool isUrgent = request.status == 'segera' ||
        (request.createdAt != null &&
            DateTime.now().difference(request.createdAt!).inHours < 3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTaskDetail(request, ctrl),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
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
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title + category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Category chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: avatarColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  request.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: avatarColor,
                                  ),
                                ),
                              ),
                              if (isUrgent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B35),
                                    borderRadius: BorderRadius.circular(5),
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
                          const SizedBox(height: 4),
                          Text(
                            request.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCCCCCC)),
                  ],
                ),

                // Description preview
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),

                // Meta row: budget | duration | mode
                Row(
                  children: [
                    _metaChip(
                      Icons.payments_outlined,
                      ctrl.formatRupiah(request.budget),
                      const Color(0xFF1BAB8A),
                    ),
                    const SizedBox(width: 8),
                    _metaChip(
                      Icons.schedule_outlined,
                      request.duration,
                      const Color(0xFF888888),
                    ),
                    const SizedBox(width: 8),
                    _metaChip(
                      request.mode == 'Tatap Muka'
                          ? Icons.location_on_outlined
                          : Icons.videocam_outlined,
                      request.mode,
                      const Color(0xFF888888),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFFCCCCCC),
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Task Detail Bottom Sheet ─────────────────────────────────────────────

  void _showTaskDetail(RequestModel request, RequestController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(request: request, ctrl: ctrl),
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final RequestModel request;
  final RequestController ctrl;

  const _TaskDetailSheet({required this.request, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F6F8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + category
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _categoryChip(request.category),
                    const SizedBox(height: 16),

                    // Description
                    if (request.description.isNotEmpty) ...[
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Detail rows
                    _detailCard([
                      _detailRow('Tanggal', request.date, Icons.calendar_today_outlined),
                      _detailRow('Waktu', request.time, Icons.schedule_outlined),
                      _detailRow('Lokasi', request.location, Icons.location_on_outlined),
                      _detailRow('Durasi', request.duration, Icons.timer_outlined),
                      _detailRow('Mode', request.mode,
                          request.mode == 'Tatap Muka'
                              ? Icons.people_outlined
                              : Icons.videocam_outlined),
                    ]),
                    const SizedBox(height: 12),

                    // Budget
                    _detailCard([
                      _detailRow(
                        'Budget Maksimal',
                        ctrl.formatRupiah(request.budget),
                        Icons.payments_outlined,
                        valueColor: const Color(0xFF1BAB8A),
                        valueBold: true,
                      ),
                      _detailRow(
                        'Estimasi Total Biaya',
                        ctrl.formatRupiah(request.totalEstimasi),
                        Icons.calculate_outlined,
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Offer button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.handshake_outlined,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Ajukan Penawaran',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1BAB8A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1BAB8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1BAB8A),
        ),
      ),
    );
  }

  Widget _detailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: children
            .expand((w) => [w, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon, {
    Color valueColor = const Color(0xFF333333),
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1BAB8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor,
                  fontWeight:
                      valueBold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
