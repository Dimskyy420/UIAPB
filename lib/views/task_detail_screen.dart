import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/bid_model.dart';
import '../controller/riwayat_controller.dart';
import '../controller/chat_controller.dart';
import 'chat_ui_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final RequestModel request;
  final RiwayatController controller;
  final String? highlightBidId;

  const TaskDetailScreen({
    super.key,
    required this.request,
    required this.controller,
    this.highlightBidId,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = controller.isOwner(request);
    final statusColor = _statusColor[request.status] ?? const Color(0xFF888888);
    final statusLabel =
        RiwayatController.requestStatusLabel[request.status] ?? request.status;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, statusLabel, statusColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildBudgetCard(),
                  const SizedBox(height: 24),
                  if (isOwner)
                    _BidsSection(request: request, controller: controller)
                  else if (highlightBidId != null)
                    _MyBidSection(
                      request: request,
                      controller: controller,
                      bidId: highlightBidId!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _statusColor = {
    'menunggu': Color(0xFFFFA726),
    'berjalan': Color(0xFF1BAB8A),
    'selesai': Color(0xFF2196F3),
    'dibatalkan': Color(0xFFEF5350),
  };

  Widget _buildAppBar(
      BuildContext context, String statusLabel, Color statusColor) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF1BAB8A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1BAB8A), Color(0xFF0F7A63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(
                      label: request.category,
                      bgColor: Colors.white.withOpacity(0.2),
                      textColor: Colors.white),
                  const SizedBox(width: 8),
                  _Chip(
                      label: statusLabel,
                      bgColor: statusColor.withOpacity(0.25),
                      textColor: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Detail Tugas'),
          const SizedBox(height: 12),
          if (request.description.isNotEmpty) ...[
            Text(request.description,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF555555), height: 1.5)),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),
          ],
          _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: request.date.isEmpty ? '-' : request.date),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Waktu',
              value: request.time.isEmpty ? '-' : request.time),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Durasi',
              value: request.duration.isEmpty ? '-' : request.duration),
          const SizedBox(height: 10),
          _DetailRow(
              icon: request.mode == 'Tatap Muka'
                  ? Icons.location_on_outlined
                  : Icons.videocam_outlined,
              label: 'Mode',
              value: request.mode),
          if (request.location.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
                icon: Icons.map_outlined,
                label: 'Lokasi',
                value: request.location),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Informasi Biaya'),
          const SizedBox(height: 12),
          _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Budget Maksimal',
              value: controller.formatRupiah(request.budget),
              valueColor: const Color(0xFF1BAB8A),
              valueBold: true),
          const SizedBox(height: 10),
          _DetailRow(
              icon: Icons.calculate_outlined,
              label: 'Estimasi Total',
              value: controller.formatRupiah(request.totalEstimasi)),
        ],
      ),
    );
  }
}

// ─── Penawaran masuk (owner / requester view) ─────────────────────────────────

class _BidsSection extends StatelessWidget {
  final RequestModel request;
  final RiwayatController controller;

  const _BidsSection({required this.request, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (request.id == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<int>(
          stream: controller.streamBidCount(request.id!),
          builder: (_, snap) {
            final count = snap.data ?? 0;
            return Row(
              children: [
                const _SectionTitle(title: 'Penawaran Masuk'),
                const SizedBox(width: 8),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1BAB8A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<BidModel>>(
          stream: controller.streamBidsForRequest(request.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: Color(0xFF1BAB8A), strokeWidth: 2),
                ),
              );
            }
            final bids = snapshot.data ?? [];
            if (bids.isEmpty) {
              return _Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: const [
                        Icon(Icons.hourglass_empty_rounded,
                            size: 36, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 8),
                        Text('Belum ada penawaran',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: bids
                  .map((bid) => _BidCard(
                        bid: bid,
                        requestId: request.id!,
                        requestTitle: request.title,
                        requesterId: request.userId,
                        requestStatus: request.status,
                        controller: controller,
                        showActions: true,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Bid sendiri (helper view) ────────────────────────────────────────────────

class _MyBidSection extends StatelessWidget {
  final RequestModel request;
  final RiwayatController controller;
  final String bidId;

  const _MyBidSection({
    required this.request,
    required this.controller,
    required this.bidId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Penawaranmu'),
        const SizedBox(height: 12),
        FutureBuilder<BidModel?>(
          future: controller.getBidById(request.id ?? '', bidId),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final bid = snap.data!;
            return Column(
              children: [
                _BidCard(
                  bid: bid,
                  requestId: request.id ?? '',
                  requestTitle: request.title,
                  requesterId: request.userId,
                  requestStatus: request.status,
                  controller: controller,
                  isHighlighted: true,
                  showActions: false, // helper tidak ada tombol apapun di sini
                ),
                // Helper hanya lihat tombol Chat, tidak ada tombol Selesai
                if (bid.status == 'diterima')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _ChatButton(
                      requestId: request.id ?? '',
                      requestTitle: request.title,
                      requesterId: request.userId,
                      helperUid: bid.helperUid,
                      isPeminta: false,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Bid Card ─────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final String requestId;
  final String requestTitle;
  final String requesterId;
  final String requestStatus;
  final RiwayatController controller;
  final bool isHighlighted;
  final bool showActions;

  const _BidCard({
    required this.bid,
    required this.requestId,
    required this.requestTitle,
    required this.requesterId,
    required this.requestStatus,
    required this.controller,
    this.isHighlighted = false,
    this.showActions = true,
  });

  static const _bidStatusLabel = {
    'menunggu': 'Menunggu',
    'diterima': 'Diterima ✓',
    'ditolak': 'Ditolak',
  };

  static const _bidStatusColor = {
    'menunggu': Color(0xFFFFA726),
    'diterima': Color(0xFF1BAB8A),
    'ditolak': Color(0xFFEF5350),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _bidStatusColor[bid.status] ?? const Color(0xFF888888);
    final statusLabel = _bidStatusLabel[bid.status] ?? bid.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF1BAB8A)
              : const Color(0xFFEEEEEE),
          width: isHighlighted ? 1.5 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header: avatar, harga, status ──────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      const Color(0xFF1BAB8A).withOpacity(0.15),
                  child: Text(
                    bid.helperUid.isNotEmpty
                        ? bid.helperUid[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Color(0xFF1BAB8A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.formatRupiah(bid.hargaTawar),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1BAB8A)),
                      ),
                      if (bid.createdAt != null)
                        Text(
                          controller.timeAgo(bid.createdAt!),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF999999)),
                        ),
                    ],
                  ),
                ),
                _Chip(
                    label: statusLabel,
                    bgColor: statusColor.withOpacity(0.12),
                    textColor: statusColor),
              ],
            ),

            // ─── Pesan helper ────────────────────────────────────────────────
            if (bid.pesan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${bid.pesan}"',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontStyle: FontStyle.italic,
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // ─── Aksi: Tolak / Terima (menunggu) ────────────────────────────
            if (showActions && bid.status == 'menunggu') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _tolak(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFEF5350)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Tolak',
                          style: TextStyle(
                              color: Color(0xFFEF5350),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _terima(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1BAB8A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Terima',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ]

            // ─── Aksi: Chat + Selesai (diterima, requester view) ─────────────
            else if (showActions && bid.status == 'diterima') ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),

              // Tombol Buka Chat
              _ChatButton(
                requestId: requestId,
                requestTitle: requestTitle,
                requesterId: requesterId,
                helperUid: bid.helperUid,
                isPeminta: true,
              ),

              const SizedBox(height: 8),

              // Tombol Selesai atau label sudah selesai
              if (requestStatus != 'selesai')
                _SelesaiButton(requestId: requestId)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: Color(0xFF2196F3)),
                      SizedBox(width: 6),
                      Text(
                        'Tugas Telah Selesai',
                        style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _terima(BuildContext context) async {
    if (bid.id == null) return;
    final error = await controller.terimaPenawaran(
        requestId: requestId, bidId: bid.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Penawaran diterima! 🎉'),
      backgroundColor:
          error == null ? const Color(0xFF1BAB8A) : Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _tolak(BuildContext context) async {
    if (bid.id == null) return;
    final error = await controller.tolakPenawaran(
        requestId: requestId, bidId: bid.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Penawaran ditolak.'),
      backgroundColor:
          error == null ? Colors.grey.shade600 : Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─── Tombol Selesai ───────────────────────────────────────────────────────────

class _SelesaiButton extends StatefulWidget {
  final String requestId;

  const _SelesaiButton({required this.requestId});

  @override
  State<_SelesaiButton> createState() => _SelesaiButtonState();
}

class _SelesaiButtonState extends State<_SelesaiButton> {
  bool _isLoading = false;

  Future<void> _konfirmasiSelesai() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tandai Selesai?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Pastikan tugas sudah benar-benar selesai dikerjakan sebelum mengkonfirmasi.',
          style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Selesai',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({'status': 'selesai'});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tugas ditandai selesai! ✅'),
          backgroundColor: const Color(0xFF2196F3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _konfirmasiSelesai,
        icon: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF2196F3)),
              )
            : const Icon(Icons.check_circle_outline_rounded,
                size: 16, color: Color(0xFF2196F3)),
        label: Text(
          _isLoading ? 'Memproses...' : 'Tandai Selesai',
          style: const TextStyle(
              color: Color(0xFF2196F3),
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2196F3)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Chat Button ──────────────────────────────────────────────────────────────

class _ChatButton extends StatelessWidget {
  final String requestId;
  final String requestTitle;
  final String requesterId;
  final String helperUid;
  final bool isPeminta;

  const _ChatButton({
    required this.requestId,
    required this.requestTitle,
    required this.requesterId,
    required this.helperUid,
    required this.isPeminta,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _bukaChat(context),
        icon: const Icon(Icons.chat_bubble_outline_rounded,
            size: 16, color: Colors.white),
        label: const Text(
          'Buka Chat',
          style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1BAB8A),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Future<void> _bukaChat(BuildContext context) async {
    final ctrl = ChatController();

    final roomId = await ctrl.getOrCreateChatRoom(
      requestId: requestId,
      requestTitle: requestTitle,
      requesterId: requesterId,
      helperId: helperUid,
    );

    if (roomId == null || !context.mounted) return;

    final otherUid = isPeminta ? helperUid : requesterId;
    final initials = otherUid.length >= 2
        ? otherUid.substring(0, 2).toUpperCase()
        : otherUid.toUpperCase();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatUIScreen(
          roomId: roomId,
          otherUid: otherUid,
          otherInitials: initials,
          otherColor: const Color(0xFF1BAB8A),
          taskTitle: requestTitle,
          isPeminta: isPeminta,
          ctrl: ctrl,
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A)));
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _Chip(
      {required this.label,
      required this.bgColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool valueBold;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF333333),
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1BAB8A)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '-' : value,
                  style: TextStyle(
                      fontSize: 13,
                      color: valueColor,
                      fontWeight:
                          valueBold ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}