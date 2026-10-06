import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_receiver/constants/app_theme.dart';
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
    final selected = widget.selected;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) {
        setState(() => _isTapped = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isTapped = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isTapped ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill behind the icon: filled gradient when active.
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 50,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected ? AppTheme.accentGradient : null,
                    color: selected ? null : Colors.transparent,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: SvgPicture.asset(
                    widget.icon,
                    width: widget.iconWidth,
                    height: widget.iconHeight,
                    color: selected ? Colors.white : Colors.black,
                  ),
                ),
                if (widget.showBadge && widget.badgeValue > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.badgeValue}',
                            style: const TextStyle(fontFamily: 'Sora',
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
            const SizedBox(height: 3),
            Text(
              widget.name,
              style: TextStyle(fontFamily: 'Sora',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.accent : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
