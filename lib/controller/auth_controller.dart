import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/emailjs_service.dart';
import '../services/otp_service.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;

  Future<String?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Login dibatalkan';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCred =
          await _auth.signInWithCredential(credential);
      final User? user = userCred.user;
      if (user == null) return 'Gagal mendapatkan data user';

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'university': '',
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
        });
      } else {
        final data = doc.data();
        if (data?['emailVerified'] == null) {
          await _db.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });
        }
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCred.user;
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        final isVerified = doc.data()?['emailVerified'] as bool? ?? false;
        if (!isVerified) {
          await sendLoginOtp();
        }
        return {'error': null, 'needsOtp': !isVerified};
      }

      return {'error': null, 'needsOtp': false};
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Email tidak ditemukan';
        case 'wrong-password':
          msg = 'Kata sandi salah';
        case 'invalid-email':
          msg = 'Format email tidak valid';
        case 'user-disabled':
          msg = 'Akun telah dinonaktifkan';
        case 'too-many-requests':
          msg = 'Terlalu banyak percobaan. Coba lagi nanti';
        default:
          msg = e.message ?? 'Login gagal';
      }
      return {'error': msg, 'needsOtp': false};
    } catch (e) {
      return {'error': e.toString(), 'needsOtp': false};
    }
  }

  Future<String?> registerWithEmail({
    required String name,
    required String university,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (name.trim().isEmpty) return 'Nama tidak boleh kosong';
    if (university.trim().isEmpty) return 'Universitas tidak boleh kosong';
    if (email.trim().isEmpty) return 'Email tidak boleh kosong';
    if (password.length < 6) return 'Kata sandi minimal 6 karakter';
    if (password != confirmPassword) return 'Kata sandi tidak cocok';

    try {
      final UserCredential userCred =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = userCred.user;
      if (user == null) return 'Gagal membuat akun';

      await user.updateDisplayName(name.trim());

      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'university': university.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      await _auth.signOut();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'weak-password':
          return 'Kata sandi terlalu lemah';
        default:
          return e.message ?? 'Registrasi gagal';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendLoginOtp() async {
    final user = _auth.currentUser;
    if (user == null) return 'User tidak ditemukan';
    if (user.email == null) return 'Email tidak tersedia';

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final name = doc.data()?['name'] as String? ?? 'Pengguna';

      final otp = await OtpService.generateAndSave(user.uid);

      final sent = await EmailJsService.sendOtp(
        toEmail: user.email!,
        toName: name,
        otpCode: otp,
      );

      if (!sent) return 'Gagal mengirim email. Periksa koneksi dan coba lagi.';
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> isEmailOtpVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['emailVerified'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> verifyLoginOtp(String inputOtp) async {
    final user = _auth.currentUser;
    if (user == null) return 'User tidak ditemukan';

    try {
      final error = await OtpService.verify(user.uid, inputOtp);
      if (error == null) {
        await _db.collection('users').doc(user.uid).set(
          {'emailVerified': true},
          SetOptions(merge: true),
        );
      }
      return error;
    } catch (e) {
      return 'Gagal memperbarui data diverifikasi: $e';
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}