import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppNotificationService {
  static final _db = FirebaseFirestore.instance;

  // ─── Kirim notifikasi ke user tertentu ────────────────────────────────────
  static Future<void> send({
    required String toUid,     // UID penerima notifikasi
    required String title,     // Judul notif
    required String body,      // Isi pesan notif
    String type = 'general',   // Tipe: 'bid_received' | 'bid_accepted' | 'general' | 'chat'
    String? requestId,         // ID request terkait (opsional)
    String? roomId,            // ID chat room (opsional)
  }) async {
    try {
      await _db.collection('notifications').add({
        'toUid': toUid,
        'title': title,
        'body': body,
        'type': type,
        'requestId': requestId,
        'roomId': roomId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── Stream notifikasi yang belum dibaca milik user aktif ─────────────────
  static Stream<QuerySnapshot> streamUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  // ─── Tandai notifikasi sudah dibaca ───────────────────────────────────────
  static Future<void> markAsRead(String docId) async {
    try {
      await _db.collection('notifications').doc(docId).update({'isRead': true});
    } catch (_) {}
  }

  // ─── Tandai semua notif user sebagai sudah dibaca ─────────────────────────
  static Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await _db
          .collection('notifications')
          .where('toUid', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (_) {}
  }
}
