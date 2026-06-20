import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget avatar profil yang reusable.
/// Menampilkan foto jika [photoUrl] tersedia, fallback ke inisial.
/// Bisa digunakan untuk user sendiri maupun user lain (via [uid]).
class ProfileAvatar extends StatelessWidget {
  /// URL foto profil (optional). Jika null, tampilkan [initials].
  final String? photoUrl;

  /// Inisial untuk fallback ketika foto tidak ada.
  final String initials;

  /// Radius lingkaran avatar.
  final double radius;

  /// Warna background ketika tidak ada foto.
  final Color backgroundColor;

  /// Ukuran font inisial.
  final double? fontSize;

  /// Warna teks inisial.
  final Color initialsColor;

  /// Tampilkan border putih di sekitar avatar.
  final bool showBorder;

  /// Lebar border.
  final double borderWidth;

  /// Warna border.
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.radius = 22,
    this.backgroundColor = const Color(0xFFFF9800),
    this.fontSize,
    this.initialsColor = Colors.white,
    this.showBorder = false,
    this.borderWidth = 2,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? NetworkImage(photoUrl!)
          : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              initials,
              style: TextStyle(
                color: initialsColor,
                fontWeight: FontWeight.w700,
                fontSize: fontSize ?? (radius * 0.55),
              ),
            )
          : null,
    );

    if (!showBorder) return avatarWidget;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: avatarWidget,
    );
  }
}

/// Widget avatar yang secara otomatis mengambil data dari Firestore
/// berdasarkan [uid]. Cocok untuk menampilkan avatar user lain.
class FirestoreProfileAvatar extends StatelessWidget {
  /// UID user yang akan ditampilkan fotonya.
  final String uid;

  /// Radius lingkaran avatar.
  final double radius;

  /// Warna background fallback.
  final Color backgroundColor;

  /// Tampilkan border putih.
  final bool showBorder;

  const FirestoreProfileAvatar({
    super.key,
    required this.uid,
    this.radius = 22,
    this.backgroundColor = const Color(0xFF1BAB8A),
    this.showBorder = false,
  });

  String _getInitials(String name, String uid) {
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.trim().substring(0, name.trim().length.clamp(1, 2)).toUpperCase();
    }
    return uid.isNotEmpty
        ? uid.substring(0, uid.length.clamp(1, 2)).toUpperCase()
        : '??';
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return ProfileAvatar(
        photoUrl: null,
        initials: '?',
        radius: radius,
        backgroundColor: backgroundColor,
        showBorder: showBorder,
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? data?['displayName'] ?? '';
        final photoUrl = data?['photoUrl'] as String?;
        final initials = _getInitials(name.toString(), uid);

        return ProfileAvatar(
          photoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
          initials: initials,
          radius: radius,
          backgroundColor: backgroundColor,
          showBorder: showBorder,
        );
      },
    );
  }
}
