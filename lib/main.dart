import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:food_receiver/push/NotificationService.dart';
import 'package:food_receiver/ui/SuperAdmin/super_admin.dart';
import 'package:food_receiver/ui/Store%20Owners/store_owner_stores.dart';
import 'package:food_receiver/ui/home_screen.dart';
import 'package:food_receiver/utils/AppTranslations.dart';
import 'package:food_receiver/utils/battery_optimization.dart';
import 'package:food_receiver/utils/global.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'api/api.dart';
import 'api/repository/api_repository.dart';
import 'constants/constant.dart';
import 'constants/routes.dart';
import 'init_app.dart';
import 'models/order_model.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final FirebaseMessaging _fcm = FirebaseMessaging.instance;

int badgeCount = 0;

final Set<int> _backgroundProcessedOrders = <int>{};

final Map<int, DateTime> _backgroundProcessingTime = <int, DateTime>{};

final Set<String> _processedNotifications = <String>{};

final Map<String, DateTime> _notificationTimestamps = <String, DateTime>{};

void _cleanOldBackgroundProcessedOrders() {
  final now = DateTime.now();
  final thirtyMinutesAgo = now.subtract(const Duration(minutes: 30));

  _backgroundProcessingTime.removeWhere((orderId, time) => time.isBefore(thirtyMinutesAgo));
  _backgroundProcessedOrders.removeWhere((orderId) => !_backgroundProcessingTime.containsKey(orderId));

  print("🧹 Background: Cleaned old processed orders. Current tracked: ${_backgroundProcessedOrders.length}");
}

Future<String> ensureCorrectBaseUrl() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    String? savedBaseUrl = prefs.getString(valueShared_BASEURL);

    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      print("✅ Found saved base URL: $savedBaseUrl");
      await Api.init(); // Reinitialize API with saved URL
      return savedBaseUrl;
    } else {
      print("⚠️ No base URL found, using default");
      String defaultUrl = "https://magskr.com/";
      await prefs.setString(valueShared_BASEURL, defaultUrl);
      await Api.init();
      return defaultUrl;
    }
  } catch (e) {
    print("❌ Error ensuring base URL: $e");
    String defaultUrl = "https://magskr.com/";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(valueShared_BASEURL, defaultUrl);
      await Api.init();
    } catch (_) {}
    return defaultUrl;
  }
}

Future<bool> validateEnvironmentConsistency() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedBaseUrl = prefs.getString(valueShared_BASEURL);

    if (savedBaseUrl == null) {
      print("⚠️ No base URL saved, cannot validate environment");
      return false;
    }

    print("🔍 Current saved base URL: $savedBaseUrl");

    // Check if it's Test or Prod environment
    if (savedBaseUrl.contains("magskr.de")) {
      print("✅ Environment: TEST (magskr.de)");
      return true;
    } else if (savedBaseUrl.contains("magskr.com")) {
      print("✅ Environment: PROD (magskr.com)");
      return true;
    } else {
      print("⚠️ Unknown environment: $savedBaseUrl");
      return false;
    }
  } catch (e) {
    print("❌ Error validating environment: $e");
    return false;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }

  try {
    Firebase.app();
  } catch (e) {
    await Firebase.initializeApp();
  }


  // ✅ CRITICAL: Initialize local notifications in background
  try {
    await _initializeLocalNotificationsForBackground();
    print("✅ Background notifications initialized successfully");
  } catch (e) {
    print("🔥 Background handler triggered");
  }
  // ✅ FIRST: Ensure correct base URL is set
  String baseUrl = await ensureCorrectBaseUrl();
  bool isValidEnvironment = await validateEnvironmentConsistency();

  print("🌐 Background - Using base URL: $baseUrl");
  print("✅ Environment validation: ${isValidEnvironment ? 'PASSED' : 'FAILED'}");

  // Clean old processed orders
  _cleanOldBackgroundProcessedOrders();
  // String title = '';
  String title = message.notification?.title ?? message.data['title'] ?? '';

  String body = '';
  if (message.notification != null) {
    title = message.notification?.title ?? '';
    body = message.notification?.body ?? '';
  }
  if (title.isEmpty && message.data.isNotEmpty) {
    title = message.data['title'] ?? message.data['Title'] ?? '';
    body = message.data['body'] ?? message.data['Body'] ?? message.data['message'] ?? '';
  }
  if (title.contains('Reservation')) {
    RegExp regExp = RegExp(r'#(\d+)');
    Match? match = regExp.firstMatch(body);

    if (match != null) {
      int reservationID = int.parse(match.group(1)!);
      await getReservationInForeground(reservationID);
    }
    print('🔥 Background title: $title');
    print('🔥 Background body: $body');
    print('🔥 Background raw data: ${message.data}');

    // Replace the existing duplicate check with:
    String notificationKey = "${title}_$body";
    final now = DateTime.now();
    final thirtySecondsAgo = now.subtract(const Duration(seconds: 30));
    _processedNotifications.add(notificationKey);
    _notificationTimestamps[notificationKey] = now;
    // Check for duplicate notification
    bool isDuplicate = _processedNotifications.any((existingKey) {
      return existingKey.contains(title) && existingKey.contains(body);
    });

    if (isDuplicate) {
      print("🚫 Duplicate notification detected, skipping: $title");
      return;
    }
// ✅ Check if app is in foreground to prevent double notifications
    bool isAppInForeground = false;
    try {
      // This will be null in true background, but available if app is just minimized
      isAppInForeground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    } catch (e) {
      // We're in true background, continue with background notification
      isAppInForeground = false;
    }

    if (!isAppInForeground && title.contains('New Order') && body.isNotEmpty &&
        title.isNotEmpty) {
      // Track this notification
      _processedNotifications.add(notificationKey);
      _notificationTimestamps[notificationKey] = now;

      await _showBackgroundOrderNotification(title, body);
      print("✅ Background notification shown: $title");
    }
    // ✅ Only show notification if it contains 'New Order' and has valid content
    if (title.contains('New Order') && body.isNotEmpty && title.isNotEmpty) {
      // Track this notification
      _processedNotifications.add(notificationKey);
      _notificationTimestamps[notificationKey] = now;

      await _showBackgroundOrderNotification(title, body);
      print("✅ Background notification shown: $title");
    } else {
      print("🚫 Invalid notification ignored - Title: '$title', Body: '$body'");
    }

    badgeCount++;
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        try {
          await AppBadgePlus.updateBadge(badgeCount);
        } catch (_) {}
      }
    } catch (e) {
      print('❌ Badge update failed: $e');
    }

    // Extract order ID and process
    if (title.contains('New Order') && body.isNotEmpty) {
      RegExp regex = RegExp(r'#(\d+)');
      Match? match = regex.firstMatch(body);

      if (match != null) {
        String orderNumberStr = match.group(1)!;
        try {
          int orderNumber = int.parse(orderNumberStr);
          print("🆔 Background - Extracted Order ID: $orderNumber");

          // ✅ ENHANCED: Check for duplicate processing with time window
          final now = DateTime.now();
          final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

          // Clean old processing records
          _backgroundProcessingTime.removeWhere((id, time) =>
              time.isBefore(fiveMinutesAgo));
          _backgroundProcessedOrders.removeWhere((
              id) => !_backgroundProcessingTime.containsKey(id));

          if (_backgroundProcessedOrders.contains(orderNumber)) {
            DateTime? lastProcessed = _backgroundProcessingTime[orderNumber];
            if (lastProcessed != null && now
                .difference(lastProcessed)
                .inMinutes < 5) {
              print("🚫 Background - Order $orderNumber processed recently (${now
                  .difference(lastProcessed)
                  .inMinutes} mins ago), skipping");
              return;
            }
          }

          // Mark as being processed with current timestamp
          _backgroundProcessedOrders.add(orderNumber);
          _backgroundProcessingTime[orderNumber] = now;
          print("✅ Background - Marked order $orderNumber as processing at ${now
              .toString()}");

          // Get SharedPreferences with retries
          SharedPreferences? prefs;
          String? bearerKey;
          String? storeID;

          for (int attempt = 0; attempt < 5; attempt++) {
            try {
              print("🔄 Attempt ${attempt + 1}/5 to get fresh preferences");

              prefs = await SharedPreferences.getInstance();
              await prefs.reload();
              await Future.delayed(const Duration(milliseconds: 500));

              bearerKey = prefs.getString(valueShared_BEARER_KEY);
              storeID = prefs.getString(valueShared_STORE_KEY);

              print("🔍 Attempt ${attempt + 1} - Token: ${bearerKey?.substring(
                  0, 20) ?? 'NULL'}...");
              print("🔍 Attempt ${attempt + 1} - Store: $storeID");

              if (bearerKey != null && bearerKey.isNotEmpty) {
                print("✅ Token found on attempt ${attempt + 1}");
                break;
              }

              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              print("❌ Attempt ${attempt + 1} failed: $e");
            }
          }

          // Token validation
          if (bearerKey == null || bearerKey.isEmpty) {
            print(
                "❌ Background - No bearer token found, removing from processed and skipping");
            _backgroundProcessedOrders.remove(orderNumber);
            return;
          }

          // Get settings with retries
          bool autoAccept = false;
          bool autoPrint = false;

          for (int i = 0; i < 5; i++) {
            try {
              print("🔄 Settings read attempt ${i + 1}/5");

              await prefs!.reload();
              await Future.delayed(const Duration(milliseconds: 300));

              autoAccept = prefs.getBool('auto_order_accept') ?? false;
              autoPrint = prefs.getBool('auto_order_print') ?? false;

              print("🔍 Settings attempt ${i + 1}:");
              print("🔍 Auto Accept: $autoAccept");
              print("🔍 Auto Print: $autoPrint");

              if (autoAccept || autoPrint) {
                print("✅ Found enabled settings on attempt ${i + 1}");
                break;
              }

              if (i < 4) {
                prefs = await SharedPreferences.getInstance();
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } catch (e) {
              print("❌ Settings read attempt ${i + 1} failed: $e");
              await Future.delayed(const Duration(milliseconds: 300));
            }
          }

          print("✅ Background - Valid token found: ${bearerKey.substring(
              0, 20)}...");
          print("✅ Background - Store ID: ${storeID ?? 'MISSING'}");
          print("✅ Background - Final Auto Accept: $autoAccept");
          print("✅ Background - Final Auto Print: $autoPrint");
          print("🌐 Background - Confirmed base URL: $baseUrl");

          // Early exit if both features are disabled
          if (!autoAccept && !autoPrint) {
            print(
                "ℹ️ Background - Both auto features disabled, notification shown only");
            _backgroundProcessedOrders.remove(orderNumber);
            return;
          }

          String savedLocale = prefs!.getString('selected_language') ?? 'de';

          try {
            Get.put(AppTranslations());
            Get.updateLocale(Locale(savedLocale));
          } catch (e) {
            print("⚠️ GetX initialization error: $e");
          }

          print('🌍 Background locale set to: $savedLocale');
          print("🔍 Final Check - Auto Accept: $autoAccept");
          print("🔍 Final Check - Auto Print: $autoPrint");

          // Process the order
          if (autoAccept || autoPrint) {
            print(
                "✅ Background - At least one auto feature enabled, processing order");
            print("📤 Background - All API calls will use base URL: $baseUrl");
            await handleBackgroundOrderComplete(
                orderNumber, prefs, bearerKey, storeID);
          }
        } catch (e) {
          print('❌ Error parsing order number: $e');
          if (orderNumberStr.isNotEmpty) {
            try {
              int failedOrderNumber = int.parse(orderNumberStr);
              _backgroundProcessedOrders.remove(failedOrderNumber);
              _backgroundProcessingTime.remove(failedOrderNumber);
            } catch (_) {}
          }
        }
      } else {
        print("❌ Could not extract order number from: $body");
        print(
            "🚫 Background - Invalid notification without order number, ignoring");
      }
    } else {
      print("🚫 Background - Non-order notification ignored: '$title'");
    }
  }
  // if (title.contains('New Order')) {
  //   Get.offAllNamed('/home', arguments: {'initialTab': 0});
  // } else if (title.contains('Reservation')) {
  //   Get.offAllNamed('/home', arguments: {'initialTab': 1});
  // }

  if (title.contains('New Order')) {
    // ✅ Navigate to home with tab 0
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.offAllNamed('/home', arguments: {'initialTab': 0});
    });
  } else if (title.contains('Reservation')) {
    // ✅ Navigate to home with tab 1
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.offAllNamed('/home', arguments: {'initialTab': 1});
    });
  }
}

Future<void> _initializeLocalNotificationsForBackground() async {
  print("🔧 Initializing background local notifications...");

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    requestCriticalPermission: true, // ✅ Added for critical notifications
  );

  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
    macOS: darwinInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ CRITICAL: Create notification channel for background with proper sound
  final channel = AndroidNotificationChannel(
    'order_channel',
    'Order Notifications',
    description: 'This channel is used for order alerts',
    importance: Importance.max,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000]),
    enableLights: true,
    ledColor: const Color.fromARGB(255, 255, 0, 0),
    showBadge: true,
    // Add this to prevent dismiss sounds
   // groupId: 'order_group',
  );
  // ✅ CRITICAL: Ensure channel is created in background
  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(channel);
    print("✅ Background notification channel created successfully");
  } else {
    print("❌ Failed to get Android implementation for background");
  }

  print("✅ Background local notifications initialized");
}

Future<void> _showBackgroundOrderNotification(String title, String body) async {
  print("📢 Showing background notification");

  final androidDetails = AndroidNotificationDetails(
    'order_channel',
    'Order Notifications',
    channelDescription: 'This channel is used for order alerts',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    fullScreenIntent: false, // ❌ disable full screen intent unless required
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    autoCancel: true,   // ✅ dismissable
    ongoing: false,     // ✅ not sticky
    onlyAlertOnce: true, // ✅ play sound only first time
    channelShowBadge: true,
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'alarm.caf',
    badgeNumber: badgeCount,
    categoryIdentifier: 'ORDER_CATEGORY',
   // interruptionLevel: InterruptionLevel.critical,
    interruptionLevel: InterruptionLevel.timeSensitive,
    threadIdentifier: 'order-thread',
  );

  final platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: iosDetails,
  );

  int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  try {
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformDetails,
    );
    print("✅ Background notification shown with ID: $notificationId");
  } catch (e) {
    print("❌ Error showing background notification: $e");
  }
}

Future<void> handleBackgroundOrderComplete(int orderNumber, SharedPreferences prefs, String bearerKey, String? storeID) async {
  try {
    print("🚀 Background order processing started for: $orderNumber");

    // ✅ ENSURE CORRECT BASE URL IS SET BEFORE API CALLS
    String? savedBaseUrl = prefs.getString(valueShared_BASEURL);
    await debugSharedPreferencesSettings();
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      print("🔧 Background - Using saved base URL: $savedBaseUrl");
      // Ensure API is initialized with correct base URL
      await Api.init();
    } else {
      print("⚠️ Background - No base URL found, setting default");
      await prefs.setString(valueShared_BASEURL, "https://magskr.com/");
      await Api.init();

      savedBaseUrl = "https://magskr.com/";
    }

    print("🔑 Using token: ${bearerKey.substring(0, 20)}...");
    print("🏪 Using store: ${storeID ?? 'NULL'}");
    print("🌐 Using base URL: $savedBaseUrl"); // ✅ CONFIRM BASE URL

    bool autoAccept = prefs.getBool('auto_order_accept') ?? false;
    bool autoPrint = prefs.getBool('auto_order_print') ?? false;

    print("🔍 Auto Accept: $autoAccept");
    print("🔍 Auto Print: $autoPrint");

    if (!autoAccept && !autoPrint) {
      print("ℹ️ Background - Both auto accept and auto print disabled");
      return;
    }

    // Step 1: Get order data
    print("📥 Background - Fetching order data for order: $orderNumber");
    print("📥 Background - API will call: ${savedBaseUrl}orders/$orderNumber"); // ✅ CONFIRM FULL URL

    try {
      final orderData = await ApiRepo().getNewOrderData(bearerKey, orderNumber);

      print("✅ Background - Order data retrieved: ID ${orderData.id}");
      print("🔍 Order status: ${orderData.orderStatus}");

      // ✅ FIXED LOGIC: Process based on order status
      if (orderData.orderStatus == 2) {
        print("✅ Background - Order already accepted");

        // ✅ Only print if auto print is enabled
        if (autoPrint) {
          print("🖨️ Background - Auto printing already accepted order");
          await backgroundPrintOrder(orderData, prefs);
          print("✅ Background - Auto print attempt completed");
        } else {
          print("ℹ️ Background - Auto print disabled for accepted order");
        }
      } else if (orderData.orderStatus == 1) {
        print("⏳ Background - Order is pending (status: 1)");

        // ✅ FIXED: Only proceed if auto accept is enabled
        if (autoAccept) {
          print("🤖 Background - Auto accepting pending order: $orderNumber");
          print("📤 Background - API will call: ${savedBaseUrl}orders/${orderData.id}/status"); // ✅ CONFIRM ACCEPT URL

          Map<String, dynamic> jsonData = {
            "order_status": 2,
            "approval_status": 2,
          };

          final acceptResult = await ApiRepo().orderAcceptDecline(
              bearerKey, jsonData, orderData.id ?? 0);

          print("✅ Background - Order auto-accepted successfully");

          // ✅ Only print after accept if auto print is also enabled
          if (autoPrint) {
            print("🖨️ Background - Auto printing after accept");
            await Future.delayed(const Duration(seconds: 3));

            print("📥 Background - Fetching updated order for printing");
            print("📥 Background - API will call: ${savedBaseUrl}orders/$orderNumber"); // ✅ CONFIRM GET URL

            final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderNumber);

            print("📋 Background - Updated order retrieved for printing");
            await backgroundPrintOrder(updatedOrder, prefs);
            print("✅ Background - Auto print after accept completed");
          } else {
            print("ℹ️ Background - Auto print disabled, only accepted order");
          }
        } else {
          print("ℹ️ Background - Auto accept disabled, ignoring pending order");
          print("ℹ️ Background - Pending orders should NOT be printed without acceptance");
          return;
        }
      } else {
        print("⚠️ Background - Unknown order status: ${orderData.orderStatus}");
        return;
      }

      // Step 4: Refresh orders if store ID available
      if (storeID != null && storeID.isNotEmpty) {
        print("🔄 Background - Refreshing orders list...");
        print("📤 Background - Refresh API will call: ${savedBaseUrl}orders/filter"); // ✅ CONFIRM REFRESH URL
        await refreshOrdersInBackground(bearerKey, storeID);
      } else {
        print("⚠️ Background - Skipping orders refresh (no store ID)");
      }

      print("🎉 Background processing completed for order: $orderNumber");

    } catch (apiError) {
      print("❌ Background - API Error: $apiError");
      // ✅ CHECK IF ERROR IS RELATED TO WRONG BASE URL
      String errorString = apiError.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('not found')) {
        print("❌ Background - Possible wrong base URL issue!");
        print("❌ Background - Current base URL: $savedBaseUrl");
      }
    }

  } catch (e) {
    print("❌ Background handler error: $e");
    print("❌ Error stack: ${e.toString()}");
  }
}

Future<void> backgroundPrintOrder(Order order, SharedPreferences prefs) async {
  try {
    print("🖨️ ========== BACKGROUND PRINT STARTED ==========");
    print("🖨️ Order ID: ${order.id}");
    print("🖨️ Order Status: ${order.orderStatus}");
    print("🖨️ Invoice: ${order.invoice?.invoiceNumber ?? 'NULL'}");

    // ✅ Enhanced printer IP detection with multiple attempts
    String selectedIp = '';
    await prefs.reload();
    await Future.delayed(const Duration(milliseconds: 100));

// ✅ Always check printer_ip_0 first and validate it exists
    String? primaryIp = prefs.getString('printer_ip_0');
    if (primaryIp != null && primaryIp.trim().isNotEmpty) {
      selectedIp = primaryIp.trim();
    }
    // Method 1: Try primary printer IP
    //String? primaryIp = prefs.getString('printer_ip_0');
    print("🖨️ Primary printer_ip_0: '${primaryIp ?? 'NULL'}'");

    if (primaryIp != null && primaryIp.trim().isNotEmpty) {
      selectedIp = primaryIp.trim();
      print("✅ Using primary printer IP: '$selectedIp'");
    } else {
      print("⚠️ Primary printer IP empty, searching alternatives...");

      // Method 2: Search all possible printer IP keys
      List<String> possibleKeys = [
        'printer_ip_0',
        'printer_ip_1',
        'printer_ip_2',
        'printer_ip_3',
        'printer_ip_4',
        'selected_printer_ip',
        'printer_ip',
        'default_printer_ip'
      ];

      for (String key in possibleKeys) {
        String? ip = prefs.getString(key);
        print("🔍 Checking $key: '${ip ?? 'NULL'}'");

        if (ip != null && ip.trim().isNotEmpty) {
          selectedIp = ip.trim();
          print("✅ Found printer IP in $key: '$selectedIp'");
          break;
        }
      }

      // Method 3: Check all keys containing 'printer' or 'ip'
      if (selectedIp.isEmpty) {
        print("🔍 Searching all SharedPreferences keys...");
        Set<String> allKeys = prefs.getKeys();

        for (String key in allKeys) {
          if (key.toLowerCase().contains('printer') || key.toLowerCase().contains('ip')) {
            var value = prefs.get(key);
            print("🔍 Found key '$key': $value");

            if (value is String && value.trim().isNotEmpty) {
              selectedIp = value.trim();
              print("✅ Using IP from $key: '$selectedIp'");
              break;
            }
          }
        }
      }
    }

    if (selectedIp.isEmpty) {
      print("❌ Background - No printer IP found in any location");
      print("🔍 All SharedPreferences keys: ${prefs.getKeys()}");
      return;
    }

    // ✅ Validate IP format (basic check)
    if (!selectedIp.contains('.')) {
      print("❌ Background - Invalid IP format: '$selectedIp'");
      return;
    }

    // ✅ Enhanced Store Name Detection
    String storeName = '';

    // Method 1: Try common store name keys (OrderScreen से आने वाले)
    List<String> storeNameKeys = [
      'store_name',                    // OrderScreen से save होता है
      valueShared_STORE_NAME,         // Backup key
      'cached_store_name',            // _preloadStoreData से
      'restaurant_name',
      'shop_name',
      'business_name',
      'outlet_name'
    ];

    for (String key in storeNameKeys) {
      String? name = prefs.getString(key);
      print("🏪 Checking store key '$key': '${name ?? 'NULL'}'");

      if (name != null && name.trim().isNotEmpty) {
        storeName = name.trim();
        print("✅ Found store name in '$key': '$storeName'");
        break;
      }
    }

    // Method 2: Search all keys containing 'store' or 'restaurant' or 'shop'
    if (storeName.isEmpty) {
      print("🔍 Searching all keys for store name...");
      Set<String> allKeys = prefs.getKeys();

      for (String key in allKeys) {
        String lowerKey = key.toLowerCase();
        if (lowerKey.contains('store') || lowerKey.contains('restaurant') ||
            lowerKey.contains('shop') || lowerKey.contains('business')) {
          var value = prefs.get(key);
          print("🔍 Found potential store key '$key': $value");

          if (value is String && value.trim().isNotEmpty && !value.contains('@') && !value.contains('.')) {
            storeName = value.trim();
            print("✅ Using store name from '$key': '$storeName'");
            break;
          }
        }
      }
    }

    // Method 3: Fallback - check if any string value looks like a store name
    if (storeName.isEmpty) {
      print("🔍 Final fallback - checking all string values...");
      Set<String> allKeys = prefs.getKeys();

      for (String key in allKeys) {
        var value = prefs.get(key);
        if (value is String && value.trim().isNotEmpty &&
            value.length > 2 && value.length < 50 &&
            !value.contains('@') && !value.contains('http') &&
            !value.contains('.com') && !value.contains('Bearer') &&
            !RegExp(r'^\d+$').hasMatch(value)) {

          print("🔍 Potential store name in '$key': '$value'");
          // You can add more filtering logic here if needed
        }
      }
    }

    if (storeName.isEmpty) {
      storeName = 'Restaurant'; // Fallback name
      print("⚠️ No store name found, using fallback: '$storeName'");
    }

    // ✅ Check invoice data
    if (order.invoice == null || (order.invoice?.invoiceNumber ?? '').isEmpty) {
      print("⚠️ Background - Invoice data missing, attempting print anyway");
    }

    String savedLocale = prefs.getString('selected_language') ?? 'de';
    print("🌐 Background - Using locale: $savedLocale");
    print("🖨️ Background - Final printer IP: '$selectedIp'");
    print("🏪 Background - Final store name: '$storeName'");

    // ✅ Call print function with detailed logging
    print("🖨️ Background - Calling PrinterHelperEnglish.printInBackground...");
    //
    // await PrinterHelperEnglish.printInBackground(
    //   order: order,
    //   ipAddress: selectedIp,
    //   store: storeName,  // ✅ Now passing actual store name
    //   locale: savedLocale,
    // );

    print("✅ Background print function call completed");
    print("🖨️ ========== BACKGROUND PRINT ENDED ==========");

  } catch (e) {
    print("❌ Background print error: $e");
    print("❌ Print error stack: ${e.toString()}");
  }
}

Future<void> debugSharedPreferencesSettings() async {
  try {
    print("🔍 ========== SHARED PREFERENCES DEBUG ==========");

    // Method 1: Check existing instance
    SharedPreferences prefs1 = await SharedPreferences.getInstance();
    await prefs1.reload();

    // Method 2: Create new instance
    SharedPreferences prefs2 = await SharedPreferences.getInstance();
    await prefs2.reload();

    print("🔍 Instance 1 Settings:");
    print("🔍   auto_order_accept: ${prefs1.getBool('auto_order_accept')}");
    print("🔍   auto_order_print: ${prefs1.getBool('auto_order_print')}");
    print("🔍   auto_order_remote_accept: ${prefs1.getBool('auto_order_remote_accept')}");
    print("🔍   auto_order_remote_print: ${prefs1.getBool('auto_order_remote_print')}");

    print("🔍 Instance 2 Settings:");
    print("🔍   auto_order_accept: ${prefs2.getBool('auto_order_accept')}");
    print("🔍   auto_order_print: ${prefs2.getBool('auto_order_print')}");
    print("🔍   auto_order_remote_accept: ${prefs2.getBool('auto_order_remote_accept')}");
    print("🔍   auto_order_remote_print: ${prefs2.getBool('auto_order_remote_print')}");

    // Show all keys
    print("🔍 All keys in SharedPreferences:");
    Set<String> allKeys = prefs2.getKeys();
    for (String key in allKeys) {
      if (key.contains('auto') || key.contains('print') || key.contains('accept')) {
        var value = prefs2.get(key);
        print("🔍   $key: $value (${value.runtimeType})");
      }
    }

    print("🔍 ========== DEBUG END ==========");

  } catch (e) {
    print("❌ Debug SharedPreferences error: $e");
  }
}

Future<void> refreshOrdersInBackground(String bearerKey, String storeID) async {
  try {
    print("🔄 Background - Refreshing orders from server...");
    print("🔑 Token: ${bearerKey.substring(0, 20)}...");
    print("🏪 Store: $storeID");

    DateTime formatted = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(formatted);

    final Map<String, dynamic> data = {
      "store_id": storeID,
      "target_date": date,
      "limit": 0,
      "offset": 0,
    };

    final result = await ApiRepo().orderGetApiFilter(bearerKey, data);

    if (result.isNotEmpty && result.first.code == null) {
      print("✅ Background - Orders refreshed successfully: ${result.length} orders");
    } else {
      print("⚠️ Background - Orders refresh returned no data");
    }

  } catch (e) {
    print("❌ Background refresh error: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Firebase - Only initialize on supported platforms
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      Firebase.app();
    } catch (e) {
      await Firebase.initializeApp();
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS-specific: request permissions
    await _requestIOSPermissions();

    // Present notifications when app is in foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local-notifications
    await _initializeLocalNotifications();

    // Push-notification service wrapper (pass the initialized plugin instance)
    NotificationService.initialize(flutterLocalNotificationsPlugin);

    // Register foreground / opened-app listeners
    _registerForegroundListeners();
  } else {
    print("⚠️ Firebase not supported on ${Platform.operatingSystem}");
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);


  await initApp();
  runApp(const AppLifecycleObserver(child: MyApp()));
}

Future<void> _requestIOSPermissions() async {
  if (Platform.isIOS) {
    print('🎯 Requesting iOS notifications permissions...');
    NotificationSettings iosSettings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,  // ✅ ADD THIS
      provisional: false,
    );
    print('🛡️ iOS permission status: ${iosSettings.authorizationStatus}');

    // ✅ ADD: Request critical alerts separately if needed
    if (iosSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ iOS notifications authorized');
    }
  }
}

void _registerForegroundListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("🔥 Raw message received: ${message.toMap()}");

    String title = message.notification?.title ?? message.data['title'] ?? '';
    String body = message.notification?.body ?? message.data['body'] ?? '';

    // ✅ Show notification regardless of app state
    if ((title.contains('New Order') || title.contains('Reservation')) && body.isNotEmpty) {
      await _showOrderNotification(title, body);

      // ✅ CRITICAL: Refresh orders immediately when new order arrives
      if (title.contains('New Order')) {
        print("📄 New order received - Triggering refresh");
        await getOrdersInBackground();
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🔔 Notification tapped - App was in background");
    String title = message.notification?.title ?? message.data['title'] ?? '';

    SharedPreferences.getInstance().then((prefs) {
      final sessionID = prefs.getString(valueShared_BEARER_KEY);

      if (sessionID != null) {
        int targetTab = 0;
        if (title.contains('New Order')) {
          targetTab = 0;
        } else if (title.contains('Reservation')) {
          targetTab = 1;
        }

        print("🎯 Navigating to tab: $targetTab from any screen");

        // ✅ ALWAYS use offAll to clear stack and go to HomeScreen
        Get.offAll(
              () => const HomeScreen(),
          arguments: {'initialTab': targetTab},
          transition: Transition.noTransition,
        );

        // ✅ Refresh orders after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          callOrderApiFromNotification();
        });
      } else {
        Get.offAllNamed('/splash');
      }
    });
  });

  _fcm.getInitialMessage().then((message) async {
    if (message != null) {
      print("🔔 App opened from terminated state via notification");
      String title = message.notification?.title ?? message.data['title'] ?? '';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final sessionID = prefs.getString(valueShared_BEARER_KEY);

      if (sessionID != null) {
        int targetTab = 0;
        if (title.contains('New Order')) {
          targetTab = 0;
        } else if (title.contains('Reservation')) {
          targetTab = 1;
        }

        print("🎯 Initial message - Navigating to tab: $targetTab");

        // ✅ Store the tab for later navigation
        await prefs.setString('pending_notification_tab', targetTab.toString());

        // ✅ Refresh orders
        Future.delayed(const Duration(milliseconds: 500), () {
          callOrderApiFromNotification();
        });
      }
    }
  });
}

void checkBatteryOptimization() async {
  bool isIgnored = await isIgnoringBatteryOptimizations();
  if (!isIgnored) {
    await askIgnoreBatteryOptimizations();
  }
}

Future<void> askIgnoreBatteryOptimizations() async {
  if (Platform.isAndroid) {
    const platform = MethodChannel('com.food.mandeep.foodApptest/battery');

    try {
      final bool isIgnoring =
      await platform.invokeMethod('isIgnoringBatteryOptimizations');

      if (!isIgnoring) {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:com.food.mandeep.foodApptest',
        );
        await intent.launch();
      }
    } on PlatformException {
      debugPrint('❌ Failed to request battery-optimisation exemption');
    }
  }
}

Future<void> _initializeLocalNotifications() async {
  if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
    print("⚠️ Local notifications not supported on ${Platform.operatingSystem}");
    return;
  }
  // --- Android settings --------------------------------------------------
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  // --- iOS / macOS settings ---------------------------------------------
  final darwinInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    requestCriticalPermission: true,
    notificationCategories: [
      DarwinNotificationCategory(
        'ORDER_NOTIFICATION',  // Category ID (must match in NotificationService)
        actions: <DarwinNotificationAction>[
          // DarwinNotificationAction.defaultAction(
          //   'id_1',
          //   'View Order',
          // )
          DarwinNotificationAction.plain(
            'id_1',
            'View Order',
          ),
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.customDismissAction,
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      ),
    ],
  );

  // Combine for all platforms -------------------------------------------
  final initSettings = InitializationSettings(
    android: androidInit,
    iOS: darwinInit,
    macOS: darwinInit,
  );

  // Initialise plugin ----------------------------------------------------
  // await flutterLocalNotificationsPlugin.initialize(
  //   initSettings,
  //   onDidReceiveNotificationResponse: (NotificationResponse response) {
  //     String? payload = response.payload;
  //     if (payload != null) {
  //       int tabIndex = int.parse(payload);
  //       Get.offAllNamed('/home', arguments: {'initialTab': tabIndex});
  //     }
  //     callOrderApiFromNotification();
  //   },
  // );
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("🔔 Local notification tapped");
      String? payload = response.payload;

      if (payload != null) {
        int tabIndex = int.parse(payload);
        print("🎯 Notification payload tab: $tabIndex");

        // ✅ Always navigate to HomeScreen clearing all routes
        Get.offAll(
              () => const HomeScreen(),
          arguments: {'initialTab': tabIndex},
          transition: Transition.noTransition,
        );

        // ✅ Refresh after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          callOrderApiFromNotification();
        });
      }
    },
  );

  final channel = AndroidNotificationChannel(
    'order_notifications_v1',  // ✅ Use same ID everywhere
    'Order Notifications',
    description: 'Notifications for new orders and reservations',
    importance: Importance.max,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    showBadge: true,
  );

  // Create Android notification channel
  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(channel);
    print('✅ Android notification channel created');
  }

  // Runtime permission (Android 13+)
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
    print('✅ Android notification permission requested');
  }

  print('✅ Local notifications initialized');

  // // Android notification channel (high importance) ----------------------
  // const channel = AndroidNotificationChannel(
  //   //'order_channel',
  //   'order_notifications_v1',
  //   'Order Notifications',
  //   description: 'This channel is used for order alerts',
  //   importance: Importance.high,
  //   sound: RawResourceAndroidNotificationSound('alarm'),
  //   playSound: true,
  // );
  //
  // await flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //     AndroidFlutterLocalNotificationsPlugin>()
  //     ?.createNotificationChannel(channel);
  //
  // // Runtime permission (Android 13+) ------------------------------------
  // if (Platform.isAndroid && await Permission.notification.isDenied) {
  //   await Permission.notification.request();
  // }
}

const String orderChannelId = 'order_channel_v2';

const String silentChannelId = 'order_channel_silent';

Future<void> _showOrderNotification(String title, String body) async {
  print("📢 Showing notification");
  String payload = title.contains('New Order') ? '0' : '1';

  final androidDetails = AndroidNotificationDetails(
    'order_channel',
    'Order Notifications',
    channelDescription: 'Order alerts with sound',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    autoCancel: true,
    ongoing: false,
    onlyAlertOnce: true,
    when: DateTime.now().millisecondsSinceEpoch,
  );

  final iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'alarm.caf',
    badgeNumber: badgeCount,
    categoryIdentifier: 'ORDER_CATEGORY', // ✅ Add this
  );

  final platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  try {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload, // ✅ This is important
    );
    print("✅ Notification shown with payload: $payload");
  } catch (e) {
    print("❌ Error: $e");
  }
}

Future<void> callOrderApiFromNotification() async {
  debugPrint('ðŸ"ž API called from notification tap!');
  await getOrdersInBackground();

  // âœ… Call Super Admin refresh if controller exists
  try {
    if (Get.isRegistered<SuperAdminController>()) {
      final controller = Get.find<SuperAdminController>();
      await controller.triggerRefresh();
      print('âœ… Super Admin orders refreshed from notification');
    }
  } catch (e) {
    print('â„¹ï¸ Super Admin controller not found: $e');
  }

  // Refresh Store Owner screen if controller exists
  try {
    if (Get.isRegistered<StoreOwnerController>()) {
      final controller = Get.find<StoreOwnerController>();
      await controller.triggerRefresh();
      print('Store Owner orders refreshed from notification');
    }
  } catch (e) {
    print('Store Owner controller not found: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: appRoutes(),
      theme: ThemeData(primaryColor: Colors.blue),
      translations: AppTranslations(),
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      builder: (_, child) => AppUpdateChecker(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class AppUpdateChecker extends StatefulWidget {
  final Widget child;

  const AppUpdateChecker({super.key, required this.child});

  @override
  State<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends State<AppUpdateChecker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    clearBadgeOnAppOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      clearBadgeOnAppOpen();
    }
  }

  void clearBadgeOnAppOpen() async {
    badgeCount = 0;

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      try {
        await AppBadgePlus.updateBadge(0);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}