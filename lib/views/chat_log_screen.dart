import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../controller/chat_controller.dart';
import 'chat_ui_screen.dart';

class ChatLogScreen extends StatefulWidget {
  const ChatLogScreen({super.key});

  @override
  State<ChatLogScreen> createState() => _ChatLogScreenState();
}

class _ChatLogScreenState extends State<ChatLogScreen>
    with SingleTickerProviderStateMixin {
  final ChatController _ctrl = ChatController();
  late final TabController _tabController;

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChatList(ctrl: _ctrl, filterRole: 'requester'),
                  _ChatList(ctrl: _ctrl, filterRole: 'helper'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pesan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              StreamBuilder<int>(
                stream: _ctrl.streamTotalUnread(),
                builder: (_, snap) {
                  final count = snap.data ?? 0;
                  return Text(
                    count > 0
                        ? '$count pesan belum dibaca'
                        : 'Semua pesan sudah dibaca',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF888888)),
                  );
                },
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.search_rounded,
                color: Color(0xFF555555), size: 20),
          ),
        ],
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF1BAB8A),
          unselectedLabelColor: const Color(0xFF888888),
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded, size: 14),
                  SizedBox(width: 5),
                  Text('Saya Minta'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 14),
                  SizedBox(width: 5),
                  Text('Saya Bantu'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat List (per role) ─────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  final ChatController ctrl;
  final String filterRole; // 'requester' atau 'helper'

  const _ChatList({required this.ctrl, required this.filterRole});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: ctrl.streamMyChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1BAB8A)),
          );
        }

        final allRooms = snapshot.data ?? [];

        // Filter berdasarkan role
        final rooms = allRooms.where((room) {
          final isRequester = ctrl.currentUid == room.requesterId;
          return filterRole == 'requester' ? isRequester : !isRequester;
        }).toList();

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filterRole == 'requester'
                      ? Icons.person_outline_rounded
                      : Icons.handshake_outlined,
                  size: 56,
                  color: const Color(0xFFCCCCCC),
                ),
                const SizedBox(height: 16),
                Text(
                  filterRole == 'requester'
                      ? 'Belum ada percakapan\nsebagai peminta'
                      : 'Belum ada percakapan\nsebagai helper',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF444444),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Percakapan akan muncul setelah\nkamu mengajukan atau menerima penawaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: rooms.length,
          separatorBuilder: (_, _) => const Divider(
              height: 1, indent: 76, color: Color(0xFFEEEEEE)),
          itemBuilder: (_, i) => _ChatTile(
            room: rooms[i],
            ctrl: ctrl,
          ),
        );
      },
    );
  }
}

// ─── Chat Tile ────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final ChatController ctrl;

  const _ChatTile({required this.room, required this.ctrl});

  static const _avatarColors = [
    Color(0xFF1BAB8A),
    Color(0xFF7C4DFF),
    Color(0xFFFF7043),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final otherUid = ctrl.getOtherUid(room);
    final isRequester = ctrl.currentUid == room.requesterId;
    final unread = room.unreadCount[ctrl.currentUid] ?? 0;

    final colorIndex =
        (otherUid.isNotEmpty ? otherUid.codeUnitAt(0) : 0) %
            _avatarColors.length;
    final avatarColor = _avatarColors[colorIndex];

    final timeStr =
        room.lastMessageAt != null ? _formatTime(room.lastMessageAt!) : '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get(),
      builder: (context, snap) {
        // Ambil nama dari Firestore, fallback ke inisial UID
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] ??
            data?['displayName'] ??
            data?['firstName'] ??
            '';
        final displayName = name.toString().isNotEmpty
            ? name.toString()
            : 'Pengguna';
        final initials = _getInitials(name.toString(), otherUid);
        final isOnline = data?['isOnline'] as bool? ?? false;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatUIScreen(
                  roomId: room.id,
                  otherUid: otherUid,
                  otherInitials: initials,
                  otherColor: avatarColor,
                  taskTitle: room.requestTitle,
                  isPeminta: isRequester,
                  ctrl: ctrl,
                ),
              ),
            );
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Avatar ───────────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Online dot
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF1BAB8A)
                              : const Color(0xFFCCCCCC),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // ─── Info ─────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Badge AKTIF
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? const Color(0xFF1BAB8A)
                                        : const Color(0xFFCCCCCC),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isOnline ? 'AKTIF' : 'OFFLINE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        room.requestTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF555555),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.lastMessage.isEmpty
                                  ? 'Mulai percakapan...'
                                  : room.lastMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: unread > 0
                                    ? const Color(0xFF222222)
                                    : const Color(0xFF888888),
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1BAB8A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFFCCCCCC),
                              size: 18,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ambil inisial dari nama, fallback ke 2 karakter UID
  String _getInitials(String name, String uid) {
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.trim().substring(0, name.trim().length.clamp(1, 2)).toUpperCase();
    }
    return uid.isNotEmpty
        ? uid.substring(0, uid.length.clamp(1, 2)).toUpperCase()
        : '??';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Kemarin';
    return '${dt.day}/${dt.month}';
  }
}