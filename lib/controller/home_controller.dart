import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_model.dart';

class HomeController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ambil data user yang sedang login dan mapping ke HomeModel
  HomeModel? getUser() {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    return HomeModel(
      displayName: user.displayName ?? 'Pengguna',
      photoUrl: user.photoURL,
      email: user.email ?? '',
    );
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}