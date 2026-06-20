import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int _expiryMinutes = 5;
  static const int _maxAttempts = 5;

  // ─── Generate & Simpan OTP ────────────────────────────────────────────────

  /// Generate OTP 6 digit dan simpan ke Firestore.
  /// Return kode OTP yang di-generate.
  static Future<String> generateAndSave(String uid) async {
    final otp = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: _expiryMinutes));

    await _db.collection('otp_sessions').doc(uid).set({
      'otp': otp,
      'expiresAt': Timestamp.fromDate(expiry),
      'attempts': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return otp;
  }

  // ─── Verifikasi OTP ───────────────────────────────────────────────────────

  /// Verifikasi kode OTP yang diinput user.
  /// Return null jika berhasil, atau pesan error jika gagal.
  static Future<String?> verify(String uid, String inputOtp) async {
    try {
      final doc = await _db.collection('otp_sessions').doc(uid).get();

      if (!doc.exists) return 'Kode tidak ditemukan. Minta kode baru.';

      final data = doc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final storedOtp = data['otp'] as String;
      final attempts = (data['attempts'] as int?) ?? 0;

      // Cek expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _delete(uid);
        return 'Kode sudah kadaluarsa. Minta kode baru.';
      }

      // Cek max attempts
      if (attempts >= _maxAttempts) {
        await _delete(uid);
        return 'Terlalu banyak percobaan. Minta kode baru.';
      }

      // Cek kode
      if (inputOtp.trim() != storedOtp) {
        await _db.collection('otp_sessions').doc(uid).update({
          'attempts': FieldValue.increment(1),
        });
        final remaining = _maxAttempts - attempts - 1;
        return 'Kode salah. Sisa percobaan: $remaining';
      }

      // Sukses → hapus sesi OTP
      await _delete(uid);
      return null;
    } catch (e) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _generateCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  static Future<void> _delete(String uid) async {
    await _db.collection('otp_sessions').doc(uid).delete();
  }
}
