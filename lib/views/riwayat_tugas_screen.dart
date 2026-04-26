import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/bid_model.dart';
import '../controller/riwayat_controller.dart';
import 'task_detail_screen.dart';

class RiwayatTugasScreen extends StatefulWidget {
  const RiwayatTugasScreen({super.key});

  @override
  State<RiwayatTugasScreen> createState() => _RiwayatTugasScreenState();
}

class _RiwayatTugasScreenState extends State<RiwayatTugasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final RiwayatController _controller = RiwayatController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SayaMintaTab(controller: _controller),
                _SayaBantuTab(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 0),
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
          const Text('Riwayat Tugas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Pantau semua aktivitas tugasmu',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: const Color(0xFF1BAB8A),
            unselectedLabelColor: Colors.white70,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Saya Minta'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('Saya Bantu'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Tab Saya Minta ───────────────────────────────────────────────────────────

class _SayaMintaTab extends StatefulWidget {
  final RiwayatController controller;
  const _SayaMintaTab({required this.controller});

  @override
  State<_SayaMintaTab> createState() => _SayaMintaTabState();
}

class _SayaMintaTabState extends State<_SayaMintaTab>
    with AutomaticKeepAliveClientMixin {
  String _filterStatus = 'Semua';
  static const _filters = ['Semua', 'Aktif', 'Selesai', 'Batal'];

  // Gunakan dummy data jika Firebase belum siap (set false jika Firebase aktif)
  static const bool _useDummy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _useDummy ? _buildDummyList() : _buildFirebaseList()),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = f == _filterStatus;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF1BAB8A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1BAB8A)
                      : const Color(0xFFDDDDDD),
                ),
              ),
              child: Text(f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF555555),
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDummyList() {
    final all = widget.controller.getDummyMyRequests();
    final filtered = widget.controller.filterByStatus(all, _filterStatus);
    return _buildListView(filtered);
  }

  Widget _buildFirebaseList() {
    return StreamBuilder<List<RequestModel>>(
      stream: widget.controller.streamMyRequests(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        // Error
        if (snapshot.hasError) {
          final msg = snapshot.error.toString().replaceFirst('Exception: ', '');
          return _ErrorState(
            message: msg,
            onRetry: () => setState(() {}),
          );
        }

        final all = snapshot.data ?? [];
        final filtered =
            widget.controller.filterByStatus(all, _filterStatus);

        // Empty
        if (filtered.isEmpty) {
          return _EmptyState(
            icon: Icons.inbox_rounded,
            title: _filterStatus == 'Semua'
                ? 'Belum ada permintaan'
                : 'Tidak ada tugas $_filterStatus',
            subtitle: _filterStatus == 'Semua'
                ? 'Tekan tombol + untuk membuat permintaan baru'
                : 'Coba filter lain',
          );
        }

        return _buildListView(filtered);
      },
    );
  }

  Widget _buildListView(List<RequestModel> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${filtered.length} tugas'
              '${_filterStatus != 'Semua' ? ' · $_filterStatus' : ''}',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500),
            ),
          );
        }
        return _RequestCard(
            request: filtered[i - 1], controller: widget.controller);
      },
    );
  }
}

// ─── Tab Saya Bantu ───────────────────────────────────────────────────────────

class _SayaBantuTab extends StatefulWidget {
  final RiwayatController controller;
  const _SayaBantuTab({required this.controller});

  @override
  State<_SayaBantuTab> createState() => _SayaBantuTabState();
}

class _SayaBantuTabState extends State<_SayaBantuTab>
    with AutomaticKeepAliveClientMixin {
  static const bool _useDummy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_useDummy) return _buildDummyList();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.controller.streamMyBids(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          final msg =
              snapshot.error.toString().replaceFirst('Exception: ', '');
          return _ErrorState(
            message: msg,
            onRetry: () => setState(() {}),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _EmptyState(
            icon: Icons.handshake_outlined,
            title: 'Belum ada penawaran',
            subtitle: 'Cari tugas dan ajukan penawaranmu!',
          );
        }

        return _buildListView(items);
      },
    );
  }

  Widget _buildDummyList() {
    return _buildListView(widget.controller.getDummyMyBids());
  }

  Widget _buildListView(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: items.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${items.length} penawaran diajukan',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500),
            ),
          );
        }
        final item = items[i - 1];
        final bid = item['bid'] as BidModel;
        final requestId = item['requestId'] as String;
        final cachedRequest = item['request'] as RequestModel?;
        return _BidCard(
          bid: bid,
          requestId: requestId,
          controller: widget.controller,
          cachedRequest: cachedRequest,
        );
      },
    );
  }
}

// ─── State Widgets ─────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: Color(0xFF1BAB8A), strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Memuat data...',
              style:
                  TextStyle(fontSize: 13, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Data',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF888888)),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAB8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = const Color(0xFFCCCCCC),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444444)),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF888888)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final RiwayatController controller;

  const _RequestCard({required this.request, required this.controller});

  static const _statusColor = {
    'menunggu': Color(0xFFFFA726),
    'berjalan': Color(0xFF1BAB8A),
    'selesai': Color(0xFF2196F3),
    'dibatalkan': Color(0xFFEF5350),
  };

  static const _avatarColors = [
    Color(0xFF1BAB8A), Color(0xFF7C4DFF),
    Color(0xFFFF6B35), Color(0xFF2196F3), Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex =
        (request.title.isNotEmpty ? request.title.codeUnitAt(0) : 0) %
            _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex];
    final initials = request.title.isNotEmpty
        ? request.title.trim().split(' ').take(2).map((w) => w[0]).join()
        : '??';
    final statusColor =
        _statusColor[request.status] ?? const Color(0xFF888888);
    final statusLabel =
        RiwayatController.requestStatusLabel[request.status] ?? request.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                request: request,
                controller: controller,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(color: avatarColor, initials: initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(request.category,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888))),
                              const Spacer(),
                              _StatusBadge(
                                  label: statusLabel, color: statusColor),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MetaChip(
                        icon: Icons.schedule_outlined,
                        label:
                            request.date.isEmpty ? '-' : request.date,
                        color: const Color(0xFF888888)),
                    const SizedBox(width: 12),
                    _MetaChip(
                        icon: Icons.payments_outlined,
                        label: controller.formatRupiah(request.budget),
                        color: const Color(0xFF1BAB8A)),
                    const Spacer(),
                    _BidCountBadge(
                        requestId: request.id ?? '',
                        controller: controller),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bid Card ─────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final String requestId;
  final RiwayatController controller;
  final RequestModel? cachedRequest;

  const _BidCard({
    required this.bid,
    required this.requestId,
    required this.controller,
    this.cachedRequest,
  });

  static const _statusColor = {
    'menunggu': Color(0xFFFFA726),
    'diterima': Color(0xFF1BAB8A),
    'ditolak': Color(0xFFEF5350),
  };

  static const _avatarColors = [
    Color(0xFF1BAB8A), Color(0xFF7C4DFF),
    Color(0xFFFF6B35), Color(0xFF2196F3), Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor[bid.status] ?? const Color(0xFF888888);
    final statusLabel =
        RiwayatController.bidStatusLabel[bid.status] ?? bid.status;

    // Jika ada cache (dari dummy), pakai langsung tanpa FutureBuilder
    if (cachedRequest != null) {
      return _buildCard(context, cachedRequest!, statusColor, statusLabel);
    }

    return FutureBuilder<RequestModel?>(
      future: controller.getRequestById(requestId),
      builder: (context, snap) {
        final request = snap.data;
        return _buildCard(context, request, statusColor, statusLabel);
      },
    );
  }

  Widget _buildCard(BuildContext context, RequestModel? request,
      Color statusColor, String statusLabel) {
    final title = request?.title ?? 'Memuat...';
    final category = request?.category ?? '';
    final colorIndex =
        (title.isNotEmpty ? title.codeUnitAt(0) : 0) % _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex];
    final initials = title.isNotEmpty
        ? title.trim().split(' ').take(2).map((w) => w[0]).join()
        : '??';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: request == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                        request: request,
                        controller: controller,
                        highlightBidId: bid.id,
                      ),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(color: avatarColor, initials: initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(category,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888))),
                              const Spacer(),
                              _StatusBadge(
                                  label: statusLabel,
                                  color: statusColor),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MetaChip(
                        icon: Icons.payments_outlined,
                        label:
                            'Penawaranmu: ${controller.formatRupiah(bid.hargaTawar)}',
                        color: const Color(0xFF1BAB8A)),
                    const Spacer(),
                    if (bid.createdAt != null)
                      Text(
                        controller.timeAgo(bid.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF999999)),
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
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Color color;
  final String initials;
  const _Avatar({required this.color, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(initials.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}

class _BidCountBadge extends StatelessWidget {
  final String requestId;
  final RiwayatController controller;
  const _BidCountBadge(
      {required this.requestId, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (requestId.isEmpty || requestId.startsWith('dummy-')) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<int>(
      stream: controller.streamBidCount(requestId),
      builder: (_, snap) {
        final count = snap.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1BAB8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 11, color: Color(0xFF1BAB8A)),
              const SizedBox(width: 4),
              Text('$count penawaran masuk',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1BAB8A))),
            ],
          ),
        );
      },
    );
  }
}