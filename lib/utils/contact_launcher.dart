import 'package:url_launcher/url_launcher.dart';

Future<void> launchPhone(String phone) async {
  if (phone.trim().isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: phone.trim()));
}

Future<void> launchEmail(String email) async {
  if (email.trim().isEmpty) return;
  await launchUrl(Uri(scheme: 'mailto', path: email.trim()));
}

Future<void> launchMapAddress(String address) async {
  if (address.trim().isEmpty) return;
  final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': address});
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}