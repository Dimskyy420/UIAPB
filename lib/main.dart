import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'views/auth_screen.dart';
import 'views/home.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Init FCM & local notifications
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "DMSans"),
      // ─── Proteksi route via authStateChanges ──────────────────────────────
      // Jika token kadaluarsa / user dihapus → otomatis redirect ke AuthScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading awal
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF0F2F5),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1BAB8A),
                  strokeWidth: 2.5,
                ),
              ),
            );
          }
          // Sudah login → langsung ke Home
          if (snapshot.hasData) {
            // Pastikan FCM token tersimpan setelah restore session
            NotificationService.saveFcmToken();
            return const HomePage();
          }
          // Belum login → AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }
}