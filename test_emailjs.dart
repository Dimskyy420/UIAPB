import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _serviceId = 'service_vkc1bbn';
  const String _templateId = 'template_92gva3k'; // Note: template ID often starts with template_
  const String _publicKey = 'AhYxPnOBn2PQftj_8';

  print('Sending test email to EmailJS...');
  final response = await http.post(
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
        'to_name': 'Test User',
        'to_email': 'test@example.com',
        'otp_code': '123456',
        'expiry_minutes': '5',
        'app_name': 'TASURU',
      },
    }),
  );

  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
