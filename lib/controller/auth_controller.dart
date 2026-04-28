import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? get currentUser => _auth.currentUser;

  // ─── Google Sign-In (selalu tampilkan account picker) ─────────────────────
  Future<String?> signInWithGoogle() async {
    try {
      // Force account picker: sign out dulu agar picker selalu muncul
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

      // Simpan ke Firestore jika user baru
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'university': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return null; // null = sukses
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Login Email & Password ───────────────────────────────────────────────
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak ditemukan';
        case 'wrong-password':
          return 'Kata sandi salah';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-disabled':
          return 'Akun telah dinonaktifkan';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti';
        default:
          return e.message ?? 'Login gagal';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Register Email & Password ────────────────────────────────────────────
  Future<String?> registerWithEmail({
    required String name,
    required String university,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validasi lokal
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

      // Update display name di Firebase Auth
      await user.updateDisplayName(name.trim());

      // Simpan data ke Firestore
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'university': university.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null = sukses
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

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    // 1. Hapus FCM token agar notifikasi tidak dikirim ke device ini
    await NotificationService.clearFcmToken();
    // 2. Sign out Google
    await _googleSignIn.signOut();
    // 3. Sign out Firebase Auth
    await _auth.signOut();
  }
}