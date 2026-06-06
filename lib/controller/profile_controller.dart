import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // ─── Stream statistik user ─────────────────────────────────────────────────
  Stream<Map<String, dynamic>> streamStats() {
    if (uid.isEmpty) return Stream.value({});
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'totalTaskSelesai': data['totalTaskSelesai'] ?? 0,
        'totalEarned': data['totalEarned'] ?? 0,
      };
    });
  }

  // ─── Stream review yang diterima user ──────────────────────────────────────
  Stream<QuerySnapshot> streamMyReviews() {
    if (uid.isEmpty) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('toUid', isEqualTo: uid)
        .snapshots();
  }

  // ─── Stream history bantuan (task selesai) ─────────────────────────────────
  Stream<QuerySnapshot> streamHistoryBantuan() {
    if (uid.isEmpty) return const Stream.empty();
    return _db
        .collection('requests')
        .where('helperUid', isEqualTo: uid)
        .where('status', isEqualTo: 'selesai')
        .limit(20)
        .snapshots(); // orderBy dihapus → sort dilakukan client-side di view
  }

  // ─── Hitung jumlah user unik yang dibantu ─────────────────────────────────
  Future<int> getTotalUserDibantu() async {
    if (uid.isEmpty) return 0;
    try {
      final snap = await _db
          .collection('reviews')
          .where('toUid', isEqualTo: uid)
          .get();
      final uniqueUsers = snap.docs.map((d) => d['fromUid']).toSet();
      return uniqueUsers.length;
    } catch (_) {
      return 0;
    }
  }

  // ─── Hitung rata-rata rating ───────────────────────────────────────────────
  Future<double> getAverageRating() async {
    if (uid.isEmpty) return 0.0;
    try {
      final snap = await _db
          .collection('reviews')
          .where('toUid', isEqualTo: uid)
          .get();
      if (snap.docs.isEmpty) return 0.0;
      final total = snap.docs.fold<double>(
          0, (sum, doc) => sum + (doc['rating'] as num).toDouble());
      return total / snap.docs.length;
    } catch (_) {
      return 0.0;
    }
  }

  // ─── Submit review setelah task selesai ───────────────────────────────────
  Future<String?> submitReview({
    required String toUid,
    required String requestId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _db.collection('reviews').add({
        'fromUid': uid,
        'toUid': toUid,
        'requestId': requestId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // null = sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Public: data profil helper lain ──────────────────────────────────────

  /// Stream data user (displayName, photoUrl, dll) dari Firestore
  Stream<Map<String, dynamic>> streamPublicUser(String targetUid) {
    if (targetUid.isEmpty) return Stream.value({});
    return _db.collection('users').doc(targetUid).snapshots().map(
          (doc) => doc.data() ?? {},
        );
  }

  /// Stream statistik (taskSelesai, totalEarned) milik user lain
  Stream<Map<String, dynamic>> streamPublicStats(String targetUid) {
    if (targetUid.isEmpty) return Stream.value({});
    return _db.collection('users').doc(targetUid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'totalTaskSelesai': data['totalTaskSelesai'] ?? 0,
        'totalEarned': data['totalEarned'] ?? 0,
      };
    });
  }

  /// Stream semua ulasan yang diterima user lain
  Stream<QuerySnapshot> streamPublicReviews(String targetUid) {
    if (targetUid.isEmpty) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('toUid', isEqualTo: targetUid)
        .snapshots();
  }

  /// Rata-rata rating user lain
  Future<double> getPublicAverageRating(String targetUid) async {
    if (targetUid.isEmpty) return 0.0;
    try {
      final snap = await _db
          .collection('reviews')
          .where('toUid', isEqualTo: targetUid)
          .get();
      if (snap.docs.isEmpty) return 0.0;
      final total = snap.docs.fold<double>(
          0, (acc, doc) => acc + (doc['rating'] as num).toDouble());
      return total / snap.docs.length;
    } catch (_) {
      return 0.0;
    }
  }

  // ─── Format rupiah ─────────────────────────────────────────────────────────
  String formatRupiah(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('.');
      result.write(str[i]);
    }
    return 'Rp ${result.toString()}';
  }
}