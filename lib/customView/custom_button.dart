import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String myText;
  final double fontSize;
  final Color color;
  final Color textColor;
  final FontWeight fontWeigt;

  const CustomButton({super.key, 
    required this.myText,
    required this.onPressed,
    required this.fontSize,
    required this.color,
    required this.textColor,
    required this.fontWeigt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onPressed,
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10), // Rounded corners here
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Same radius here
              ),
              padding: EdgeInsets.zero, // Optional: to align with container edges
            ),
            child: Text(
              myText,
              style: TextStyle(
                fontSize: 17.0,
                color: textColor ?? const Color(0xffdb1514),
                fontWeight: fontWeigt,
              ),
            ),
          ),
        )
    );
  }
}

