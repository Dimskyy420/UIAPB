import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'views/auth_screen.dart';
import 'views/otp_screen.dart';
import 'views/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "DMSans"),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ───────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Animasi masuk logo
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();

    // Tunggu 2.5 detik + cek auth secara paralel
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Jalankan keduanya paralel: timer 2.5 detik & cek auth Firebase
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2500)),
      _checkAuthDestination(),
    ]);

    if (!mounted) return;

    final destination = results[1] as Widget;

    // Animasi keluar sebelum pindah
    await _animCtrl.reverse();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<Widget> _checkAuthDestination() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const AuthScreen();

      // User sudah login — cek emailVerified di Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final emailVerified = data?['emailVerified'] as bool?;

      // DEBUG — hapus setelah testing
      debugPrint('=== DEBUG 2FA ===');
      debugPrint('UID: ${user.uid}');
      debugPrint('emailVerified value: $emailVerified');
      debugPrint('Provider: ${user.providerData.map((p) => p.providerId).toList()}');
      debugPrint('=================');

      if (emailVerified == null) {
        final isGoogle =
            user.providerData.any((p) => p.providerId == 'google.com');
        final newValue = isGoogle;
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'emailVerified': newValue});
        return newValue ? const HomePage() : OtpScreen(email: user.email ?? '');
      }

      if (emailVerified) return const HomePage();
      return OtpScreen(email: user.email ?? '');
    } catch (_) {
      return const AuthScreen();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1BAB8A), Color(0xFF0D6E55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dengan animasi fade + scale
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/tasuru_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Nama app
            FadeTransition(
              opacity: _fadeAnim,
              child: const Text(
                'TASURU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),

            const SizedBox(height: 8),

            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                'Platform bantuan mahasiswa',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Loading indicator kecil di bawah
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.6),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
