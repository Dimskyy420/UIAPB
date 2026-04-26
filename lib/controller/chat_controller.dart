import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

class ChatController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ─── Buat atau ambil chat room ────────────────────────────────────────────
  // roomId = requestId + '_' + helperId (unik per pasangan request-helper)
  Future<String?> getOrCreateChatRoom({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String helperId,
  }) async {
    try {
      final roomId = '${requestId}_$helperId';

      final ref = _db.collection('chatRooms').doc(roomId);
      final doc = await ref.get();

      if (!doc.exists) {
        await ref.set({
          'requestId': requestId,
          'requestTitle': requestTitle,
          'requesterId': requesterId,
          'helperId': helperId,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': {requesterId: 0, helperId: 0},
        });
      }

      return roomId;
    } catch (e) {
      return null;
    }
  }

  // ─── Stream semua chat room milik user ───────────────────────────────────
  Stream<List<ChatRoomModel>> streamMyChatRooms() {
    if (currentUid.isEmpty) return const Stream.empty();

    // Ambil room sebagai requester
    final asRequester = _db
        .collection('chatRooms')
        .where('requesterId', isEqualTo: currentUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatRoomModel.fromMap(d.id, d.data()))
            .toList());

    // Ambil room sebagai helper
    final asHelper = _db
        .collection('chatRooms')
        .where('helperId', isEqualTo: currentUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatRoomModel.fromMap(d.id, d.data()))
            .toList());

    // Gabungkan keduanya
    return _mergeStreams(asRequester, asHelper);
  }

  Stream<List<ChatRoomModel>> _mergeStreams(
    Stream<List<ChatRoomModel>> s1,
    Stream<List<ChatRoomModel>> s2,
  ) async* {
    List<ChatRoomModel> list1 = [];
    List<ChatRoomModel> list2 = [];

    await for (final _ in Stream.periodic(
        const Duration(milliseconds: 100))) {
      // Yield gabungan
      final merged = [...list1, ...list2];
      merged.sort((a, b) => (b.lastMessageAt ?? DateTime(0))
          .compareTo(a.lastMessageAt ?? DateTime(0)));
      yield merged;
      break;
    }

    // Real-time update
    s1.listen((data) => list1 = data);
    s2.listen((data) => list2 = data);

    yield* Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) async {
      final merged = [...list1, ...list2];
      merged.sort((a, b) => (b.lastMessageAt ?? DateTime(0))
          .compareTo(a.lastMessageAt ?? DateTime(0)));
      return merged;
    });
  }

  // ─── Stream pesan dalam 1 room ────────────────────────────────────────────
  Stream<List<ChatMessageModel>> streamMessages(String roomId) {
  return _db
      .collection('chatRooms')
      .doc(roomId)
      .collection('messages')
      .orderBy('createdAt', descending: false)  // ← ubah ini
      .snapshots()
      .map((s) => s.docs
          .map((d) => ChatMessageModel.fromMap(d.id, d.data()))
          .toList());
}

  // ─── Kirim pesan ──────────────────────────────────────────────────────────
  Future<String?> sendMessage({
    required String roomId,
    required String text,
    required String otherUid,
  }) async {
    if (currentUid.isEmpty) return 'Kamu belum login.';
    if (text.trim().isEmpty) return 'Pesan tidak boleh kosong.';

    try {
      final batch = _db.batch();

      // Tambah pesan
      final msgRef = _db
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderUid': currentUid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update lastMessage & unread di room
      final roomRef = _db.collection('chatRooms').doc(roomId);
      batch.update(roomRef, {
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Tandai pesan sudah dibaca ────────────────────────────────────────────
  Future<void> markAsRead(String roomId) async {
    if (currentUid.isEmpty) return;
    try {
      await _db.collection('chatRooms').doc(roomId).update({
        'unreadCount.$currentUid': 0,
      });
    } catch (_) {}
  }

  // ─── Total unread (untuk badge di nav bar) ────────────────────────────────
  Stream<int> streamTotalUnread() {
    if (currentUid.isEmpty) return Stream.value(0);
    return _db
        .collection('chatRooms')
        .where('requesterId', isEqualTo: currentUid)
        .snapshots()
        .asyncMap((_) async {
      int total = 0;

      final asRequester = await _db
          .collection('chatRooms')
          .where('requesterId', isEqualTo: currentUid)
          .get();
      final asHelper = await _db
          .collection('chatRooms')
          .where('helperId', isEqualTo: currentUid)
          .get();

      for (final doc in [...asRequester.docs, ...asHelper.docs]) {
        final data = doc.data();
        final unread =
            (data['unreadCount'] as Map?)?.entries ?? [];
        for (final e in unread) {
          if (e.key == currentUid) total += (e.value as int);
        }
      }
      return total;
    });
  }

  // ─── Helper: nama tampilan lawan bicara ──────────────────────────────────
  String getOtherUid(ChatRoomModel room) {
    return currentUid == room.requesterId ? room.helperId : room.requesterId;
  }

  String getRoleLabel(ChatRoomModel room) {
    return currentUid == room.requesterId ? 'Peminta' : 'Helper';
  }
}