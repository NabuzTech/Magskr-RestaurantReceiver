import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_receiver/ui/Login/LoginScreen.dart';
import 'package:food_receiver/ui/Store%20Owners/store_owner_stores.dart';
import 'package:food_receiver/ui/SuperAdmin/super_admin.dart';
import 'package:food_receiver/ui/home_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'api/api.dart';
import 'constants/constant.dart';
import 'push/NotificationService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SharedPreferences _prefs;
  final supportedLocales = ['en', 'de', 'hi', 'ch'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initFlow();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _initFlow() async {
    _prefs = await SharedPreferences.getInstance();
    final sessionID = _prefs.getString(valueShared_BEARER_KEY);
    await Api.init();
    String? savedLangCode = _prefs.getString(valueShared_LANGUAGE);
    if (savedLangCode != null && supportedLocales.contains(savedLangCode)) {
      changeLanguage(savedLangCode);
    }

    Timer(const Duration(seconds: 4), () {
      if (sessionID != null) {
        // Get role_id from SharedPreferences
        int? roleId = _prefs.getInt(valueShared_ROLE_ID);

        // Check if we have a stored tab preference from notification
        String? notificationTab = _prefs.getString('notification_initial_tab');

        if (notificationTab != null) {
          _prefs.remove('notification_initial_tab');
          Get.off(() => const HomeScreen(), arguments: {'initialTab': int.parse(notificationTab)});
        } else {
          final arguments = Get.arguments;
          if (arguments != null && arguments['initialTab'] != null) {
            Get.off(() => const HomeScreen(), arguments: arguments);
          } else {
            // Navigate based on role_id
            if (roleId == 1) {
              // Super Admin
              Get.off(() => const SuperAdmin());
            }  else if (roleId == 5) {
              Get.offAll(() => const StoreOwnerStores());
            } else {
              // Regular users (role_id 2 or others)
              Get.off(() => const HomeScreen());
            }
          }
        }
      } else {
        //Get.off(() => const DesktopLoginScreen());
       Get.off(() => const LoginScreen());
      }
    });
  }

  Future<void> changeLanguage(String langCode) async {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  
        Lottie.asset(
            'assets/animations/burger.json',
            width: 350,
            height: 350,
            repeat: true, )
      ),
    );
  }
}
