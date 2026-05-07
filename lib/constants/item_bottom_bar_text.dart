import 'package:flutter/material.dart';


class ItemTextBottomBar extends StatelessWidget {
  final String icon;
  final String name;
  final bool selected;
  final bool showBadge;
  final int badgeValue;
  final VoidCallback onPressed;

  const ItemTextBottomBar({super.key, 
    required this.icon,
    required this.name,
    this.selected = false,
    this.showBadge = false,
    this.badgeValue = 0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Widget tabIcon = Container(
      child: Column(
        children: [
          IconButton(
            onPressed: onPressed,
            iconSize: 30,
            icon: Image.asset(
              icon,
              height: 25,
              width: 25,
              color: selected ? Colors.blue[900] : Colors.grey,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
                fontSize: 15.0,
                color: Colors.black,
                fontWeight: FontWeight.w400),
          )
        ],
      ),
    );

    return tabIcon;
  }
}
