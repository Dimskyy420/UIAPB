import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/bid_model.dart';
import '../controller/bid_controller.dart';

class RiwayatController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BidController _bidController = BidController();

  String get _userId => _auth.currentUser?.uid ?? '';

  bool get isLoggedIn => _userId.isNotEmpty;

  // ─── Status maps (dipakai view untuk label & warna) ───────────────────────

  static const Map<String, String> requestStatusLabel = {
    'menunggu': 'Menunggu Helper',
    'berjalan': 'Berlangsung',
    'selesai': 'Selesai',
    'dibatalkan': 'Dibatalkan',
  };

  static const Map<String, String> bidStatusLabel = {
    'menunggu': 'Menunggu Ajuan',
    'diterima': 'Diterima ✓',
    'ditolak': 'Ditolak',
  };

  // Status yang masuk ke filter "Aktif"
  static const List<String> activeStatuses = ['menunggu', 'berjalan'];

  // ─── Saya Minta: stream request milik user ────────────────────────────────

  Stream<List<RequestModel>> streamMyRequests() {
    if (!isLoggedIn) return const Stream.empty();
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                RequestModel.fromMap(d.id, d.data()))
            .toList());
  }

  // Filter list request berdasarkan tab status
  List<RequestModel> filterByStatus(
      List<RequestModel> requests, String filterStatus) {
    if (filterStatus == 'Semua') return requests;

    final statusMap = {
      'Aktif': activeStatuses,
      'Selesai': ['selesai'],
      'Batal': ['dibatalkan'],
    };

    final allowed = statusMap[filterStatus] ?? [];
    return requests.where((r) => allowed.contains(r.status)).toList();
  }

  // ─── Saya Bantu: stream bid milik user ────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamMyBids() {
    return _bidController.streamMyBids();
  }

  // ─── Detail: stream penawaran masuk pada 1 request ────────────────────────

  Stream<List<BidModel>> streamBidsForRequest(String requestId) {
    return _bidController.streamBidsForRequest(requestId);
  }

  // ─── Cek apakah user adalah pemilik request ──────────────────────────────

  bool isOwner(RequestModel request) {
    return _userId.isNotEmpty && _userId == request.userId;
  }

  // ─── Ambil 1 bid berdasarkan ID ───────────────────────────────────────────

  Future<BidModel?> getBidById(String requestId, String bidId) async {
    try {
      final doc = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('penawaran')
          .doc(bidId)
          .get();
      if (!doc.exists) return null;
      return BidModel.fromMap(doc.id, {
        ...doc.data()!,
        'requestId': requestId,
      });
    } catch (_) {
      return null;
    }
  }

  // ─── Ambil request by ID (untuk _BidCard fetch judul) ────────────────────

  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection('requests')
          .doc(requestId)
          .get();
      if (!doc.exists) return null;
      return RequestModel.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // ─── Stream jumlah penawaran (badge) ─────────────────────────────────────

  Stream<int> streamBidCount(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('penawaran')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Terima penawaran ─────────────────────────────────────────────────────

  Future<String?> terimaPenawaran(
      {required String requestId, required String bidId}) {
    return _bidController.terimaPenawaran(
        requestId: requestId, bidId: bidId);
  }

  // ─── Tolak penawaran ─────────────────────────────────────────────────────

  Future<String?> tolakPenawaran(
      {required String requestId, required String bidId}) {
    return _bidController.tolakPenawaran(
        requestId: requestId, bidId: bidId);
  }

  // ─── Format rupiah (delegasi ke RequestController) ───────────────────────

  String formatRupiah(int amount) {
    final str = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('.');
      result.write(str[i]);
    }
    return 'Rp ${result.toString()}';
  }

  // ─── Time ago helper ──────────────────────────────────────────────────────

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}