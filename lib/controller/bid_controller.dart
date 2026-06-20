import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/bid_model.dart';
import '../services/in_app_notification_service.dart';

class BidController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // ─── Cek apakah user sudah pernah menawar request ini ────────────────────
  Future<bool> hasAlreadyBid(String requestId) async {
    if (_userId.isEmpty) return false;

    final snap = await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('penawaran')
        .where('helperUid', isEqualTo: _userId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  // ─── Ajukan penawaran ─────────────────────────────────────────────────────
  // Mengembalikan null jika sukses, string pesan error jika gagal
  Future<String?> ajukanPenawaran({
    required RequestModel request,
    required String pesan,
  }) async {
    // Validasi: user harus login
    if (_userId.isEmpty) return 'Kamu harus login terlebih dahulu.';

    // Validasi: tidak boleh menawar request sendiri
    if (_userId == request.userId) {
      return 'Kamu tidak bisa menawar requestmu sendiri.';
    }

    // Validasi: ID request harus valid
    if (request.id == null || request.id!.isEmpty) {
      return 'ID request tidak valid.';
    }

    // Validasi: cek duplikat penawaran
    final sudahMenawar = await hasAlreadyBid(request.id!);
    if (sudahMenawar) {
      return 'Kamu sudah mengajukan penawaran untuk tugas ini.';
    }

    try {
      // Simpan penawaran sebagai subcollection di dalam request
      await _firestore
          .collection('requests')
          .doc(request.id)
          .collection('penawaran')
          .add({
        'helperUid': _userId,
        'hargaTawar': request.budget,
        'estimasiTotal': request.totalEstimasi,
        'pesan': pesan,
        'status': 'menunggu',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ── Kirim notifikasi in-app ke pemilik request ──────────────────────
      await InAppNotificationService.send(
        toUid: request.userId,
        title: '🙋 Ada Helper Baru!',
        body: 'Seseorang mengajukan penawaran untuk tugasmu: "${request.title}"',
        type: 'bid_received',
        requestId: request.id,
      );

      return null; // null = sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Stream semua penawaran pada 1 request (untuk pemilik tugas) ──────────
  Stream<List<BidModel>> streamBidsForRequest(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('penawaran')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => BidModel.fromMap(doc.id, {
                  ...doc.data(),
                  'requestId': requestId,
                }))
            .toList());
  }

  // ─── Stream penawaran milik user yang sedang login (riwayat helper) ───────
  // Catatan: query ini butuh composite index di Firestore
  Stream<List<Map<String, dynamic>>> streamMyBids() {
    if (_userId.isEmpty) return const Stream.empty();

    return _firestore
        .collectionGroup('penawaran')
        .where('helperUid', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final requestId =
                  doc.reference.parent.parent?.id ?? '';
              return {
                'bid': BidModel.fromMap(doc.id, {
                  ...doc.data(),
                  'requestId': requestId,
                }),
                'requestId': requestId,
              };
            }).toList());
  }

  // ─── Terima penawaran (hanya pembuat request yang bisa) ───────────────────
  Future<String?> terimaPenawaran({
    required String requestId,
    required String bidId,
  }) async {
    if (_userId.isEmpty) return 'Kamu harus login terlebih dahulu.';

    try {
      final batch = _firestore.batch();

      // Update status bid yang diterima → 'diterima'
      final bidRef = _firestore
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .doc(bidId);
      batch.update(bidRef, {'status': 'diterima'});

      // Update status request → 'berjalan'
      final requestRef = _firestore.collection('requests').doc(requestId);
      batch.update(requestRef, {'status': 'berjalan'});

      await batch.commit();

      // ── Ambil judul request ─────────────────────────────────────────────
      final reqSnap = await requestRef.get();
      final requestTitle = reqSnap.data()?['title'] as String? ?? 'tugasmu';

      // ── Tolak semua penawaran LAIN secara otomatis + kirim notif ditolak ─
      final otherBids = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .where(FieldPath.documentId, isNotEqualTo: bidId)
          .get();

      for (final doc in otherBids.docs) {
        // Update status ke 'ditolak'
        await doc.reference.update({'status': 'ditolak'});

        // Kirim notif ke setiap helper yang ditolak otomatis
        final rejectedHelperUid = doc.data()['helperUid'] as String? ?? '';
        if (rejectedHelperUid.isNotEmpty) {
          await InAppNotificationService.send(
            toUid: rejectedHelperUid,
            title: '😔 Penawaran Tidak Dipilih',
            body: 'Penawaranmu untuk tugas "$requestTitle" tidak dipilih kali ini. Jangan menyerah, coba tugas lainnya!',
            type: 'bid_rejected',
            requestId: requestId,
          );
        }
      }

      // ── Ambil helperUid dari bid yang DITERIMA ──────────────────────────
      final bidSnap = await bidRef.get();
      final acceptedHelperUid = bidSnap.data()?['helperUid'] as String? ?? '';

      // ── Kirim notif ke helper yang DITERIMA ─────────────────────────────
      if (acceptedHelperUid.isNotEmpty) {
        await InAppNotificationService.send(
          toUid: acceptedHelperUid,
          title: '🎉 Penawaran Diterima!',
          body: 'Selamat! Penawaranmu untuk tugas "$requestTitle" telah diterima. Silakan mulai kerjakan!',
          type: 'bid_accepted',
          requestId: requestId,
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Tolak penawaran MANUAL satu per satu (oleh pemilik request) ────────
  Future<String?> tolakPenawaran({
    required String requestId,
    required String bidId,
  }) async {
    if (_userId.isEmpty) return 'Kamu harus login terlebih dahulu.';

    try {
      // ── Ambil data bid sebelum diupdate (untuk tahu helperUid) ───────────
      final bidRef = _firestore
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .doc(bidId);

      final bidSnap = await bidRef.get();
      final rejectedHelperUid = bidSnap.data()?['helperUid'] as String? ?? '';

      // ── Update status bid → 'ditolak' ────────────────────────────────────
      await bidRef.update({'status': 'ditolak'});

      // ── Ambil judul request ───────────────────────────────────────────────
      final reqSnap = await _firestore
          .collection('requests')
          .doc(requestId)
          .get();
      final requestTitle = reqSnap.data()?['title'] as String? ?? 'sebuah tugas';

      // ── Kirim notif ke helper yang ditolak ───────────────────────────────
      if (rejectedHelperUid.isNotEmpty) {
        await InAppNotificationService.send(
          toUid: rejectedHelperUid,
          title: '😔 Penawaran Tidak Dipilih',
          body: 'Penawaranmu untuk tugas "$requestTitle" tidak dipilih kali ini. Jangan menyerah, coba tugas lainnya!',
          type: 'bid_rejected',
          requestId: requestId,
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Hitung jumlah penawaran pada suatu request ───────────────────────────
  Future<int> countBids(String requestId) async {
    final snap = await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('penawaran')
        .count()
        .get();
    return snap.count ?? 0;
  }
}