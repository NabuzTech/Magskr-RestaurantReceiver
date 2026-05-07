import 'dart:math';

import 'package:flutter/material.dart';

AppColor appColor = AppColor();

class AppColor {
  static final AppColor _appColor = AppColor._i();

  factory AppColor() {
    return _appColor;
  }

  AppColor._i();

  static const Color main = Color(0xFF5297F4);
  static const Color primaryColor = Color(0xFF5297F4);
  static const Color primaryDarkColor = Color(0xFF5297F4);
  static const Color primaryLightColor = Color(0xFF5297F4);
  static const Color primaryLight = Color(0xFF5297F4);
  static const Color accentColor = Color(0xff39446F);

  static const Color bgColor = Color(0xFFEAF1FF);

  final Color white = Colors.white;
  final Color black = Colors.black;
  final Color transparent = Colors.transparent;

  static const Color grey = Color(0xff898989);
  static const Color greyDark = Color(0xFF424242);
  static const Color greyLight = Color(0x23898989);
  static const Color pink = Color(0xFFFF4081);
  static const Color loginRightColor = Color(0xFF41a0e4);
  static const  loginLeftColor = Color(0xFF40b4e5);
  static const  backgroundBlueDarkColor = Color(0xFF4086e5);
  static const  backgroundBlueLightColor = Color(0xFF3face5);



  static const Color notWhite = Color(0xFFEDF0F2);
  static const Color notWhite2 = Color(0xFFF7F3F3);
  static const Color nearlyWhite = Color(0x8EE2E1E1);
  static const Color borderGreen = Color(0xff00B10E);




   Color colorBG2 = const Color(0xffBAE3F7);


  Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  Color generateRandomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];

    Random random = Random();
    return Color.fromARGB(
        255, random.nextInt(255), random.nextInt(255), random.nextInt(255));
  }
}
