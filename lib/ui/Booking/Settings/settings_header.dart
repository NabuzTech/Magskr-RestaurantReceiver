import 'package:flutter/material.dart';

/// Header for the booking settings screens: back arrow + title (these screens are pushed
/// as normal routes, so they have no app bar of their own).
class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF263238)),
            ),
          ),
        ],
      ),
    );
  }
}
