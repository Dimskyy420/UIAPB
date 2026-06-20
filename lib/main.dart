import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'views/auth_screen.dart';
import 'views/otp_screen.dart';
import 'views/home.dart';
import 'services/notification_service.dart';

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
          // Sudah login → cek emailVerified di Firestore
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
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
                final data = userSnap.data?.data() as Map<String, dynamic>?;
                final emailVerified = data?['emailVerified'] as bool?;

                // DEBUG — hapus setelah testing
                debugPrint('=== DEBUG 2FA ===');
                debugPrint('UID: ${snapshot.data!.uid}');
                debugPrint('emailVerified value: $emailVerified');
                debugPrint('Provider: ${snapshot.data!.providerData.map((p) => p.providerId).toList()}');
                debugPrint('=================');

                // Jika field belum ada → tulis ke Firestore sesuai provider
                if (emailVerified == null) {
                  final isGoogle = snapshot.data!.providerData
                      .any((p) => p.providerId == 'google.com');
                  final newValue = isGoogle; // Google = true, email = false
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .update({'emailVerified': newValue});

                  if (newValue) {
                    
                    return const HomePage();
                  } else {
                    return OtpScreen(email: snapshot.data!.email ?? '');
                  }
                }

                if (emailVerified) {
                  // Email sudah terverifikasi → masuk Home
                  return const HomePage();
                } else {
                  // Belum verifikasi OTP → Langsung tampilkan OTP Screen
                  return OtpScreen(email: snapshot.data!.email ?? '');
                }
              },
            );
          }
          // Belum login → AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }
}
