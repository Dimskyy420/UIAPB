import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../controller/profile_controller.dart';

class HelperProfileScreen extends StatefulWidget {
  final String helperUid;

  const HelperProfileScreen({super.key, required this.helperUid});

  @override
  State<HelperProfileScreen> createState() => _HelperProfileScreenState();
}

class _HelperProfileScreenState extends State<HelperProfileScreen> {
  final ProfileController _ctrl = ProfileController();
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl
        .getPublicAverageRating(widget.helperUid)
        .then((r) { if (mounted) setState(() => _avgRating = r); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _ctrl.streamPublicUser(widget.helperUid),
        builder: (context, userSnap) {
          final userData = userSnap.data ?? {};
          final name = userData['name'] as String? ?? 'Helper';
          final photoUrl = userData['photoUrl'] as String?;
          final university = userData['university'] as String? ?? '';

          final initials = _initials(name);

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, name, photoUrl, initials, university),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsCard(),
                      const SizedBox(height: 20),
                      _buildReviewsSection(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, String name, String? photoUrl,
      String initials, String university) {
    return SliverAppBar(
      expandedHeight: 220,
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
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.shade400,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 24))
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                if (university.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_outlined,
                          color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(university,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats Card ───────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _ctrl.streamPublicStats(widget.helperUid),
      builder: (context, snap) {
        final stats = snap.data ?? {};
        final taskSelesai = stats['totalTaskSelesai'] ?? 0;
        final earned = (stats['totalEarned'] ?? 0) as int;
        final ratingStr = _avgRating > 0
            ? _avgRating.toStringAsFixed(1)
            : '-';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
          ),
          child: Row(
            children: [
              _StatItem(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF2ECC71),
                label: 'Task Selesai',
                value: taskSelesai.toString(),
              ),
              _vDivider(),
              _StatItem(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFA726),
                label: 'Rating',
                value: ratingStr,
              ),
              _vDivider(),
              _StatItem(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF1BAB8A),
                label: 'Total Earned',
                value: earned > 0 ? _ctrl.formatRupiah(earned) : '-',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vDivider() => Container(
        height: 40,
        width: 1,
        color: const Color(0xFFF0F0F0),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Reviews Section ──────────────────────────────────────────────────────────

  Widget _buildReviewsSection() {
    return Column(
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
          stream: _ctrl.streamPublicReviews(widget.helperUid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                      color: Color(0xFF1BAB8A), strokeWidth: 2),
                ),
              );
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        size: 36, color: Color(0xFFCCCCCC)),
                    SizedBox(height: 8),
                    Text('Belum ada ulasan',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  ],
                ),
              );
            }

            // Sort descending by createdAt
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final tA = (dataA['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                final tB = (dataB['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(2000);
                return tB.compareTo(tA);
              });

            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final rating = (data['rating'] as num).toDouble();
                final comment = data['comment'] as String? ?? '';
                final reviewerName =
                    data['reviewerName'] as String? ?? 'Pengguna';
                final createdAt = data['createdAt'];
                String timeStr = '';
                if (createdAt != null) {
                  try {
                    final dt = (createdAt as dynamic).toDate() as DateTime;
                    final diff = DateTime.now().difference(dt);
                    if (diff.inDays > 0) {
                      timeStr = '${diff.inDays} hari lalu';
                    } else if (diff.inHours > 0) {
                      timeStr = '${diff.inHours} jam lalu';
                    } else {
                      timeStr = 'Baru saja';
                    }
                  } catch (_) {}
                }

                return _ReviewCard(
                  reviewerName: reviewerName,
                  rating: rating,
                  comment: comment,
                  timeStr: timeStr,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'H';
  }
}

// ── Stat Item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
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

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final String reviewerName;
  final double rating;
  final String comment;
  final String timeStr;

  const _ReviewCard({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info + timestamp
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFEFF9F6),
                child: Text(
                  reviewerName.isNotEmpty
                      ? reviewerName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1BAB8A)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reviewerName,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFAAAAAA))),
            ],
          ),
          const SizedBox(height: 10),
          // Bintang
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
  }
}
