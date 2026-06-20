import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailJsService {
  // ─── Ganti dengan credentials EmailJS kamu ────────────────────────────────
  // Daftar di https://www.emailjs.com → Dashboard → Email Services & Templates
  static const String _serviceId = 'service_vkc1bbn';
  static const String _templateId = 'template_92gva3k';
  static const String _publicKey = 'AhYxPnOBn2PQftj_8';
  // ───────────────────────────────────────────────────────────────────────────

  /// Kirim email OTP ke user.
  /// Return true jika berhasil, false jika gagal.
  static Future<bool> sendOtp({
    required String toEmail,
    required String toName,
    required String otpCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {
              'Content-Type': 'application/json',
              'origin': 'http://localhost',
            },
            body: jsonEncode({
              'service_id': _serviceId,
              'template_id': _templateId,
              'user_id': _publicKey,
              'template_params': {
                'to_name': toName,
                'to_email': toEmail,
                'otp_code': otpCode,
                'expiry_minutes': '5',
                'app_name': 'TASURU',
              },
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
