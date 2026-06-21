import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        .limit(10)
        .snapshots();
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
      // Increment counter task selesai milik helper
      await _db.collection('users').doc(toUid).update({
        'totalTaskSelesai': FieldValue.increment(1),
      });
      return null; // null = sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Update foto profil via URL ────────────────────────────────────────────
  /// Update photoUrl di Firestore dan Firebase Auth menggunakan URL langsung.
  /// Kembalikan true jika berhasil, false jika gagal.
  Future<bool> updateProfilePhotoUrl(String newUrl) async {
    if (uid.isEmpty) return false;
    try {
      // Update Firestore
      await _db.collection('users').doc(uid).update({'photoUrl': newUrl});

      // Update Firebase Auth profile
      await _auth.currentUser?.updatePhotoURL(newUrl);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Public: rata-rata rating helper lain ──────────────────────────────────
  Future<double> getPublicAverageRating(String helperUid) async {
    if (helperUid.isEmpty) return 0.0;
    try {
      final snap = await _db
          .collection('reviews')
          .where('toUid', isEqualTo: helperUid)
          .get();
      if (snap.docs.isEmpty) return 0.0;
      final total = snap.docs.fold<double>(
          0, (sum, doc) => sum + (doc['rating'] as num).toDouble());
      return total / snap.docs.length;
    } catch (_) {
      return 0.0;
    }
  }

  // ─── Public: stream data profil user lain ──────────────────────────────────
  Stream<Map<String, dynamic>> streamPublicUser(String helperUid) {
    if (helperUid.isEmpty) return Stream.value({});
    return _db.collection('users').doc(helperUid).snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  // ─── Public: stream statistik user lain ────────────────────────────────────
  Stream<Map<String, dynamic>> streamPublicStats(String helperUid) {
    if (helperUid.isEmpty) return Stream.value({});
    return _db.collection('users').doc(helperUid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'totalTaskSelesai': data['totalTaskSelesai'] ?? 0,
        'totalEarned': data['totalEarned'] ?? 0,
      };
    });
  }

  // ─── Public: stream ulasan yang diterima user lain ─────────────────────────
  Stream<QuerySnapshot> streamPublicReviews(String helperUid) {
    if (helperUid.isEmpty) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('toUid', isEqualTo: helperUid)
        .limit(10)
        .snapshots();
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
