import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';
  String get _displayName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Pengguna';

  // ─── Cek apakah user sudah mereview request ini ────────────────────────────
  Future<bool> hasReviewed(String requestId) async {
    if (_uid.isEmpty || requestId.startsWith('dummy-')) return false;
    try {
      final snap = await _db
          .collection('reviews')
          .where('fromUid', isEqualTo: _uid)
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─── Ambil helperUid dari bid yang diterima di sebuah request ──────────────
  Future<String?> getHelperUidForRequest(String requestId) async {
    if (requestId.startsWith('dummy-')) return null;
    try {
      final snap = await _db
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .where('status', isEqualTo: 'diterima')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['helperUid'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Submit review (requester nilai helper, atau helper nilai requester) ────
  Future<String?> submitReview({
    required String toUid,         // UID yang dinilai
    required String requestId,
    required int rating,           // 1–5
    required String ulasan,        // boleh kosong
    required String reviewerName,
  }) async {
    if (_uid.isEmpty) return 'Kamu belum login.';
    if (_uid == toUid) return 'Kamu tidak bisa menilai dirimu sendiri.';
    try {
      // Cek duplikat
      final already = await hasReviewed(requestId);
      if (already) return 'Kamu sudah memberikan ulasan untuk tugas ini.';

      await _db.collection('reviews').add({
        'fromUid': _uid,
        'toUid': toUid,
        'requestId': requestId,
        'rating': rating,
        'comment': ulasan,
        'reviewerName': reviewerName.isNotEmpty ? reviewerName : _displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── Ambil hargaTawar dari bid helper yang diterima ─────────────────
      int earned = 0;
      try {
        final bidSnap = await _db
            .collection('requests')
            .doc(requestId)
            .collection('penawaran')
            .where('helperUid', isEqualTo: toUid)
            .where('status', isEqualTo: 'diterima')
            .limit(1)
            .get();
        if (bidSnap.docs.isNotEmpty) {
          earned =
              (bidSnap.docs.first.data()['hargaTawar'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      // ── Update statistik di dokumen user helper ────────────────────────
      final Map<String, dynamic> statsUpdate = {
        'totalTaskSelesai': FieldValue.increment(1),
      };
      if (earned > 0) {
        statsUpdate['totalEarned'] = FieldValue.increment(earned);
      }
      await _db
          .collection('users')
          .doc(toUid)
          .set(statsUpdate, SetOptions(merge: true));

      return null; // null = sukses
    } catch (e) {
      return 'Gagal mengirim ulasan: ${e.toString()}';
    }
  }

  // ─── Ambil requesterUid dari sebuah request ────────────────────────────────
  Future<String?> getRequesterUidForRequest(String requestId) async {
    if (requestId.startsWith('dummy-')) return null;
    try {
      final doc = await _db.collection('requests').doc(requestId).get();
      if (!doc.exists) return null;
      return doc.data()?['userId'] as String?;
    } catch (_) {
      return null;
    }
  }
}
