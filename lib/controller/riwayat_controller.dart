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
    // Jika belum login → emit error yang informatif (bukan empty)
    if (!isLoggedIn) {
      return Stream.error(Exception('Kamu belum login. Silakan login terlebih dahulu.'));
    }

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RequestModel.fromMap(d.id, d.data()))
            .toList())
        .handleError((error) {
      // Lempar ulang error agar UI bisa menangkap dan menampilkan retry
      throw Exception(_parseFirestoreError(error));
    });
  }

  // Fallback dummy data untuk "Saya Minta" (ketika Firebase belum aktif / testing)
  List<RequestModel> getDummyMyRequests() {
    final now = DateTime.now();
    return [
      RequestModel(
        id: 'dummy-req-1',
        userId: 'dummy-user',
        category: 'Antar Barang',
        title: 'Antar Dokumen ke Kantor Pos',
        description: 'Butuh bantuan untuk mengantar dokumen penting ke kantor pos terdekat.',
        duration: '< 1 jam',
        mode: 'Tatap Muka',
        location: 'Jl. Sudirman No. 10, Jakarta',
        date: '26 Apr 2026',
        time: '14:00',
        budget: 50000,
        status: 'menunggu',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      RequestModel(
        id: 'dummy-req-2',
        userId: 'dummy-user',
        category: 'Belanja',
        title: 'Beli Obat di Apotek Century',
        description: 'Tolong belikan obat sesuai resep dokter yang sudah saya foto.',
        duration: '1-2 jam',
        mode: 'Tatap Muka',
        location: 'Apotek Century, Mall Taman Anggrek',
        date: '25 Apr 2026',
        time: '10:00',
        budget: 30000,
        status: 'berjalan',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      RequestModel(
        id: 'dummy-req-3',
        userId: 'dummy-user',
        category: 'Jasa Teknis',
        title: 'Perbaiki Laptop yang Lemot',
        description: 'Laptop saya sangat lemot dan butuh diperiksa serta dioptimasi.',
        duration: '2-4 jam',
        mode: 'Tatap Muka',
        location: 'Depok, Jawa Barat',
        date: '20 Apr 2026',
        time: '09:00',
        budget: 150000,
        status: 'selesai',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      RequestModel(
        id: 'dummy-req-4',
        userId: 'dummy-user',
        category: 'Konsultasi',
        title: 'Konsultasi Desain Logo UMKM',
        description: 'Saya ingin konsultasi desain logo untuk toko online saya.',
        duration: '1-2 jam',
        mode: 'Online',
        location: 'Online (Google Meet)',
        date: '18 Apr 2026',
        time: '15:00',
        budget: 75000,
        status: 'dibatalkan',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  // ─── Saya Bantu: stream bid milik user ────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamMyBids() {
    if (!isLoggedIn) {
      return Stream.error(Exception('Kamu belum login. Silakan login terlebih dahulu.'));
    }
    return _bidController.streamMyBids().handleError((error) {
      throw Exception(_parseFirestoreError(error));
    });
  }

  // Fallback dummy data untuk "Saya Bantu" (ketika Firebase belum aktif / testing)
  List<Map<String, dynamic>> getDummyMyBids() {
    final now = DateTime.now();
    final dummyRequests = [
      RequestModel(
        id: 'dummy-task-1',
        userId: 'other-user-1',
        category: 'Antar Barang',
        title: 'Antar Kue ke Rumah Teman',
        description: 'Butuh seseorang untuk mengantar kue ulang tahun ke alamat tujuan.',
        duration: '< 1 jam',
        mode: 'Tatap Muka',
        location: 'Kebayoran Baru, Jakarta Selatan',
        date: '26 Apr 2026',
        time: '12:00',
        budget: 40000,
        status: 'berjalan',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      RequestModel(
        id: 'dummy-task-2',
        userId: 'other-user-2',
        category: 'Jasa Teknis',
        title: 'Install Ulang Windows 10',
        description: 'Laptop perlu diinstall ulang karena terkena virus.',
        duration: '2-4 jam',
        mode: 'Tatap Muka',
        location: 'BSD City, Tangerang Selatan',
        date: '22 Apr 2026',
        time: '10:00',
        budget: 200000,
        status: 'selesai',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    return [
      {
        'bid': BidModel(
          id: 'dummy-bid-1',
          requestId: 'dummy-task-1',
          helperUid: _userId.isNotEmpty ? _userId : 'dummy-user',
          hargaTawar: 40000,
          estimasiTotal: 47000,
          pesan: 'Saya siap membantu mengantarkan kue!',
          status: 'diterima',
          createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        ),
        'requestId': 'dummy-task-1',
        'request': dummyRequests[0],
      },
      {
        'bid': BidModel(
          id: 'dummy-bid-2',
          requestId: 'dummy-task-2',
          helperUid: _userId.isNotEmpty ? _userId : 'dummy-user',
          hargaTawar: 200000,
          estimasiTotal: 222000,
          pesan: 'Berpengalaman install ulang Windows, siap membantu.',
          status: 'menunggu',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        'requestId': 'dummy-task-2',
        'request': dummyRequests[1],
      },
    ];
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
    // Cek apakah ini dummy data
    if (requestId.startsWith('dummy-')) {
      final dummies = getDummyMyBids();
      for (final item in dummies) {
        if (item['requestId'] == requestId) {
          return item['request'] as RequestModel?;
        }
      }
    }

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
    if (requestId.startsWith('dummy-')) return Stream.value(0);
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

  // ─── Filter list request berdasarkan tab status ───────────────────────────

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

  // ─── Time ago helper ──────────────────────────────────────────────────────

  String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  // ─── Helper: parse pesan error Firestore menjadi teks yang ramah ─────────

  String _parseFirestoreError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('permission-denied') || msg.contains('permission denied')) {
      return 'Akses ditolak. Pastikan kamu sudah login dengan akun yang benar.';
    }
    if (msg.contains('unavailable') || msg.contains('network')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internetmu.';
    }
    if (msg.contains('unauthenticated')) {
      return 'Sesi loginmu telah berakhir. Silakan login kembali.';
    }
    if (msg.contains('failed-precondition') || msg.contains('index')) {
      return 'Database perlu dikonfigurasi (index belum dibuat). Hubungi admin.';
    }
    if (msg.contains('belum login')) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Gagal memuat data. Coba lagi beberapa saat.';
  }
}