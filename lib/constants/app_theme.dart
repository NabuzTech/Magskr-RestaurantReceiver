import 'package:flutter/material.dart';

// App theme: white + light purple-blue gradient (replaces the old green).
class AppTheme {
  AppTheme._();

  static const Color accent = Color(0xFF7C6CF2);
  static const Color accentDark = Color(0xFF2E2A5C);
  static const Color accentLight = Color(0xFFEDEBFF);
  static const Color blue = Color(0xFF7FB2FF);
  static const Color purple = Color(0xFFA78BFA);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF3F0FF), Color(0xFFEAF2FF)],
  );
}

// Paints the page gradient behind a transparent Scaffold.
class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: child,
    );
  }
}
