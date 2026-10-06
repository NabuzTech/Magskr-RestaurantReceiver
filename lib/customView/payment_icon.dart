import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// Payment method icons from assets/images; cash uses a Material icon (no svg yet).
Widget paymentIcon(String method, {double size = 20}) {
  final m = method.toLowerCase();
  final String? svg = m == 'stripe'
      ? 'assets/images/stripe.svg'
      : m == 'paypal'
          ? 'assets/images/paypal.svg'
          : (m.startsWith('ec') || m == 'card')
              ? 'assets/images/ec.svg'
              : null;
  final Widget child = svg != null
      ? SvgPicture.asset(svg, height: size, width: size)
      : m == 'cash'
          ? Icon(Icons.payments_rounded, size: size, color: const Color(0xFF16A34A))
          : Text(method, style: const TextStyle(fontFamily: 'Sora', fontSize: 11, fontWeight: FontWeight.w600));
  return Tooltip(message: method, child: child);
}
