import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../ui/SuperAdmin/super_admin.dart';
import '../utils/global.dart';

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  // Assigned from main.dart after the plugin is initialized there
  static late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  static Future<void> initialize(FlutterLocalNotificationsPlugin notificationsPlugin) async {
    _flutterLocalNotificationsPlugin = notificationsPlugin;
    print('🔔 Initializing Notification Service...');
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // ✅ REQUEST NOTIFICATION PERMISSIONS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🛡️ Permission granted: ${settings.authorizationStatus}');

    // ✅ DISPLAY NOTIFICATIONS IN FOREGROUND
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ LISTEN FOR FOREGROUND MESSAGES
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("🔔 FirebaseMessaging onMessage: ${message.toMap()}");

      String title = message.notification?.title ?? message.data['title'] ?? '';
      String body = message.notification?.body ?? message.data['body'] ?? '';

      print('🔊 Foreground notification received');
      print('📢 Title: $title');
      print('📄 Body: $body');

      // ✅ PLAY ALARM SOUND FOR NEW ORDERS
      if ((title.contains('New Order') || title.contains('Reservation')) && body.isNotEmpty) {
        await _playAlarmSound();

        // Show local notification with sound
        await _showLocalNotification(title, body);
      }

      // ✅ HANDLE RESERVATION NOTIFICATIONS
      if (title.contains('Reservation') || title.contains('New Reservation')) {
        if (body.isNotEmpty) {
          RegExp regExp = RegExp(r'#(\d+)');
          Match? match = regExp.firstMatch(body);

          if (match != null) {
            int reservationID = int.parse(match.group(1)!);
            print('🎫 Reservation ID extracted: $reservationID');
            await getReservationInForeground(reservationID);
          }
        }
      }

      // âœ… HANDLE ORDER NOTIFICATIONS
      if (title.contains('New Order') && body.isNotEmpty) {
        print('âœ… New Order notification - triggering refresh');
        await getOrdersInBackground();

        // âœ… Refresh Super Admin if controller exists
        try {
          if (Get.isRegistered<SuperAdminController>()) {
            final controller = Get.find<SuperAdminController>();
            await controller.triggerRefresh();
            print('âœ… Super Admin refreshed from notification');
          }
        } catch (e) {
          print('â„¹ï¸ Super Admin not active: $e');
        }
      }});

    // ✅ HANDLE BACKGROUND MESSAGE TAP (App in background, notification tapped)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🎯 Notification clicked from background');
      String title = message.notification?.title ?? message.data['title'] ?? '';
      print('🔨 Title from tap: $title');

      if (title.contains('New Order')) {
        Get.offAllNamed('/home', arguments: {'initialTab': 0});
      } else if (title.contains('Reservation')) {
        Get.offAllNamed('/home', arguments: {'initialTab': 1});
      }
    });

    // ✅ HANDLE NOTIFICATION THAT LAUNCHED APP
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched by notification');
      String? title = initialMessage.notification?.title ?? initialMessage.data['title'];
      String? body = initialMessage.notification?.body ?? initialMessage.data['body'];

      print('📌 Initial notification title: $title');
      print('📌 Initial notification body: $body');

      if (title != null) {
        if (title.contains('New Order')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/home', arguments: {'initialTab': 0});
          });
        } else if (title.contains('Reservation')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/home', arguments: {'initialTab': 1});
          });
        }
      }
    }

    // ✅ LISTEN FOR FCM TOKEN REFRESH — keeps server in sync when Firebase rotates the token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed: $newToken');
      await _updateServerDeviceToken(newToken);
    });

    print('✅ Notification Service initialized successfully');
  }

  // Called on app startup (auto-login path) to ensure the server has the current FCM token.
  static Future<void> syncTokenWithServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(valueShared_BEARER_KEY) == null) return;

      String? currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken != null) {
        print('🔄 Syncing FCM token on startup...');
        await _updateServerDeviceToken(currentToken);
      }
    } catch (e) {
      print('❌ Error syncing FCM token on startup: $e');
    }
  }

  // Re-logs in silently with saved credentials to push the new device token to the server.
  // This is needed because there is no dedicated "update device token" endpoint — the login
  // API is the only call that accepts device_token.
  static Future<void> _updateServerDeviceToken(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(valueShared_USERNAME_KEY);
      final password = prefs.getString(valueShared_PASSWORD_KEY);
      final bearerKey = prefs.getString(valueShared_BEARER_KEY);

      if (bearerKey == null) {
        // Not logged in yet — token will be sent on next login
        print('ℹ️ Not logged in, new FCM token will be sent on next login');
        return;
      }

      if (username == null || password == null) {
        print('⚠️ Stored credentials not found, cannot update FCM token on server');
        return;
      }

      print('📤 Sending updated FCM token to server...');
      final result = await ApiRepo().loginApi(username, password, newToken);

      if (result.access_token != null && result.access_token!.isNotEmpty) {
        // Save the new bearer token returned from the silent re-login
        await prefs.setString(valueShared_BEARER_KEY, result.access_token!);
        print('✅ FCM token updated on server successfully');
      } else {
        print('⚠️ Silent re-login failed, FCM token not updated: ${result.message}');
      }
    } catch (e) {
      print('❌ Error updating FCM token on server: $e');
    }
  }

  // ✅ PLAY ALARM SOUND
  static Future<void> _playAlarmSound() async {
    try {
      print('🔊 Attempting to play alarm sound...');

      // Stop any currently playing audio
      await _audioPlayer.stop();

      // Play the alarm sound from assets
      await _audioPlayer.play(AssetSource('alarm.mp3'));
      print('✅ Alarm sound started playing');

      // Stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await _audioPlayer.stop();
          print('✅ Alarm sound stopped');
        } catch (e) {
          print('❌ Error stopping sound: $e');
        }
      });
    } catch (e) {
      print('❌ Error playing alarm sound: $e');
    }
  }

  // ✅ SHOW LOCAL NOTIFICATION WITH SOUND
  static Future<void> _showLocalNotification(String title, String body) async {
    try {
      print('📢 Showing local notification');

      final androidDetails = AndroidNotificationDetails(
        'order_channel',  // ✅ Changed from 'order_notifications_v1' to match
        'Order Notifications',
        channelDescription: 'Notifications for new orders and reservations',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        autoCancel: true,
        ongoing: false,
        onlyAlertOnce: false,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.caf',  // ✅ iOS uses .caf format
        categoryIdentifier: 'ORDER_NOTIFICATION',
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'order-notifications',
        subtitle: 'Order Alert',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: title.contains('New Order') ? '0' : '1',
      );

      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  // ✅ CLEANUP
  static Future<void> dispose() async {
    await _audioPlayer.stop();
    await _audioPlayer.release();
  }
}
