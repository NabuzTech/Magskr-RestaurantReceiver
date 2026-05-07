import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:flutter_svg/flutter_svg.dart';
class ItemBottomBar extends StatefulWidget {
  final String icon;          // asset path
  final String name;          // tab label
  final bool selected;        // highlight when active
  final bool showBadge;       // toggle badge on/off
  final int  badgeValue;      // value to show in badge
  final VoidCallback onPressed;
  final double? iconWidth;    // customizable icon width
  final double? iconHeight;   // customizable icon height

  const ItemBottomBar({
    super.key,
    required this.icon,
    required this.name,
    required this.onPressed,
    this.selected   = false,
    this.showBadge  = false,
    this.badgeValue = 0,
    this.iconWidth  = 20,
    this.iconHeight = 20,
  });

  @override
  State<ItemBottomBar> createState() => _ItemBottomBarState();
}

class _ItemBottomBarState extends State<ItemBottomBar> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    double containerHeight = Platform.isIOS ? 90 : 50;
    EdgeInsets containerPadding = Platform.isIOS
        ? const EdgeInsets.symmetric(horizontal: 12,)
        : const EdgeInsets.symmetric(horizontal: 11);
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isTapped = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isTapped = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: containerHeight,
        padding: containerPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isTapped
              ? Colors.grey.withOpacity(0.2)
              : Colors.transparent,
          boxShadow: _isTapped ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 1,
            ),
          ] : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isTapped ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: SvgPicture.asset(
                    widget.icon,
                    width: widget.iconWidth,
                    height: widget.iconHeight,
                    color: widget.selected ? Colors.green : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedScale(
                  scale: _isTapped ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.selected ? Colors.green : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showBadge && widget.badgeValue > 0)
              Positioned(
                top: -6,
                right: -10,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.badgeValue}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
