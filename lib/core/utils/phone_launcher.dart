import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phoneNumber) async {
  final digits = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: digits);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
