import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';

class RequestController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // ─── Submit request baru ──────────────────────────────────────────────────
  Future<String?> submitRequest(RequestModel request) async {
    try {
      final docRef = await _firestore.collection('requests').add(
            request.copyWith().toMap()
              ..addAll({
                'userId': _userId,
                'createdAt': FieldValue.serverTimestamp(),
              }),
          );
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // ─── Stream semua permintaan (Search Available Tasks) ────────────────────
  // Tidak menampilkan request milik user sendiri
  Stream<List<RequestModel>> streamAllRequests() {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
            // Filter: sembunyikan request milik diri sendiri
            .where((r) => r.userId != _userId)
            .toList());
  }

  // ─── Stream request milik user sendiri (My Requests) ─────────────────────
  Stream<List<RequestModel>> streamMyRequests() {
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ─── Ambil semua permintaan milik user (sekali ambil) ────────────────────
  Future<List<RequestModel>> getUserRequests() async {
    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Cek apakah user adalah pembuat request ───────────────────────────────
  // true  → pembuat → TIDAK boleh ajukan penawaran
  // false → helper  → BOLEH ajukan penawaran
  bool isCreator(RequestModel request) {
    return _userId.isNotEmpty && _userId == request.userId;
  }

  // ─── Update status request ────────────────────────────────────────────────
  Future<String?> updateStatus(String requestId, String newStatus) async {
    try {
      await _firestore
          .collection('requests')
          .doc(requestId)
          .update({'status': newStatus});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Hapus request (hanya pembuat) ───────────────────────────────────────
  Future<String?> deleteRequest(String requestId) async {
    try {
      // Hapus semua penawaran (subcollection) dulu
      final penawaranSnap = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .get();

      for (final doc in penawaranSnap.docs) {
        await doc.reference.delete();
      }

      // Hapus dokumen request
      await _firestore.collection('requests').doc(requestId).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Tanggal tersedia (hari ini, besok, lusa) ─────────────────────────────
  List<Map<String, String>> getAvailableDates() {
    final now = DateTime.now();
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return List.generate(3, (i) {
      final date = now.add(Duration(days: i));
      final label = i == 0 ? 'Hari ini' : i == 1 ? 'Besok' : 'Lusa';
      final sub =
          '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
      final value =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return {'label': label, 'sub': sub, 'value': value};
    });
  }

  // ─── Jam tersedia ─────────────────────────────────────────────────────────
  List<String> getAvailableTimes() {
    return [
      '07:00', '08:00', '09:00', '10:00',
      '11:00', '13:00', '14:00', '15:00',
      '16:00', '17:00', '19:00', '20:00',
    ];
  }

  // ─── Format rupiah ────────────────────────────────────────────────────────
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