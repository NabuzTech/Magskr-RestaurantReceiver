import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_receiver/ui/table%20Book/reservation.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constant.dart';
import '../constants/item_bottom_bar.dart';
import '../constants/app_color.dart';
import '../customView/CustomAppBar.dart';
import '../customView/CustomDrawer.dart';
import '../main.dart';
import '../services/app_update_service.dart';
import '../utils/global.dart';
import '../utils/keep_alive_page.dart';
import '../utils/my_application.dart';
import 'Order/OrderScreen.dart';
import 'Pos/pos.dart';
import 'Pos/pos_portrait.dart' show PosPortrait;
import 'Report/ReportScreen.dart';
import 'SuperAdmin/SuperAdmin Report/super_admin_report.dart';
import 'SuperAdmin/SuperAdminReservation/super_admin_reservation.dart';
import 'SuperAdmin/Super_admin_order/admin_order.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //static final GlobalKey<_HomeScreenState> homeKey = GlobalKey<_HomeScreenState>();

  late PageController _pageController;
  int lastIndex = 0;
  int floatIndex = 0;
  bool isSelected = false;
  bool _isDataLoaded = false;
  BuildContext? dialogContext;
  bool _fcmInitialized = false;
  int? _lastProcessedOrderId;
  String? _storeType;
  int? _roleId;

  @override
  void initState() {
    super.initState();
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);

    _pageController = PageController(initialPage: 0);

    _setupFCMListeners();
    _setupLocalNotificationTap();


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final arguments = Get.arguments;
      int targetTab = 0; // Default to 0

      // First check Get.arguments
      if (arguments != null && arguments['initialTab'] != null) {
        targetTab = arguments['initialTab'];
        print("🎯 Got initialTab from arguments: $targetTab");
      }
      // Then check pending notification tab
      else {
        String? pendingTab = prefs.getString('pending_notification_tab');
        if (pendingTab != null) {
          targetTab = int.parse(pendingTab);
          await prefs.remove('pending_notification_tab');
          print("🎯 Got pending notification tab: $targetTab");
        }
      }

      // ✅ Set the tab BEFORE loading data
      app.appController.onTabChanged(targetTab);

      // ✅ Now load the data
      await _loadInitialData();

      print("✅ Data loaded, current tab should be: $targetTab");

      // ✅ Add extra delay to ensure widget tree is fully built
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ Jump to page after everything is ready
      if (_pageController.hasClients && mounted) {
        _pageController.jumpToPage(targetTab);
        print("✅ PageController jumped to page: $targetTab");

        // ✅ Force a setState to rebuild
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          print("🔍 Checking for updates from HomeScreen");
          AppUpdateService.checkForUpdates(context);
        }
      });
    });
  }

  void _setupLocalNotificationTap() {
    // Listen for local notification taps when app is in foreground
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        String? payload = response.payload;
        if (payload != null) {
          int tabIndex = int.parse(payload);
          _openTab(tabIndex); // Navigate to appropriate tab
        }
      },
    );
  }

  Future<void> _loadInitialData() async {
    SharedPreferences freshPrefs = await SharedPreferences.getInstance();
    _storeType = freshPrefs.getString(valueShared_STORE_TYPE);
    _roleId = freshPrefs.getInt(valueShared_ROLE_ID);

    await Future.wait([
      getOrdersInBackground(),
      //getReservationsInBackground(),
    ]);

    if (mounted) {
      setState(() {
        _isDataLoaded = true;
      });
      print("✅ _isDataLoaded set to true");
    }
  }

  DateTime? _lastProcessedTime;

  void _setupFCMListeners() {
    if (_fcmInitialized) return;
    _fcmInitialized = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("DataNotification ${message.notification}");
      print('Foreground message received: Home Screen ${message.notification
          ?.title}');
      print('Message body: ${message.notification?.body}');

      final title = message.notification?.title ?? '';
      if (title.contains("New Order")) {
        final body = message.notification?.body ?? '';
        RegExp regex = RegExp(r'#(\d+)');
        Match? match = regex.firstMatch(body);

        if (match != null) {
          int orderNumber = int.parse(match.group(1)!);
          DateTime now = DateTime.now();

          bool isNewOrder = _lastProcessedOrderId != orderNumber;
          bool isTimedOut = _lastProcessedTime == null ||
              now.difference(_lastProcessedTime!) > const Duration(seconds: 3);

          if (isNewOrder || isTimedOut) {
            _lastProcessedOrderId = orderNumber;
            _lastProcessedTime = now;

            print("Order number: $orderNumber - calling API");
            getOrdersInForegrund(context, orderNumber);
            // Remove _openTab(0); - no auto navigation
          }
        }
      } else
      if (title.contains("New Reservation") || title.contains("Reservation")) {
        final body = message.notification?.body ?? ''; // Add this line
        RegExp regex = RegExp(r'#(\d+)');
        Match? match = regex.firstMatch(body);

        if (match != null) {
          int reservationNumber = int.parse(match.group(1)!);
          print("Reservation number: $reservationNumber - refreshing data");
          getReservationsInBackground();
        }
      }
    });

    // यह notification tap पर ही चलेगा
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';

      if (title.contains("New Order")) {
        _openTab(0);
        getOrdersInBackground();
      } else if (title.contains("Reservation")) {
        _openTab(1);
        getReservationsInBackground();
      }

      print('Notification Screen tapped (app opened): ${message.notification
          ?.title}');
    });
  }

  Future<bool> _onWillPop() async {
    // Check if roleId is 1 (super admin) or 5 (store owner)
    if (_roleId == 1 || _roleId == 5) {
      // Clear store ID from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(valueShared_STORE_KEY);

      // ✅ Give time for cleanup
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate back to SuperAdmin/StoreOwner screen
      Get.back();
      return false;
    }

    // Direct exit from app for regular users
    SystemNavigator.pop();
    return false;
  }

  void navigateToTab(int index) {
    _openTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final size = MediaQuery.of(context).size;

    print("🔍 Home Orientation: $orientation");
    print("🔍 Home Size: ${size.width} x ${size.height}");
    return WillPopScope(
      onWillPop: _onWillPop,
      // key: homeKey,
      child: Obx(() =>
          Scaffold(
              drawer: CustomDrawer(onSelectTab: _openTab),
              // ✅ Hide AppBar when on POS tab (index 3)
              appBar: app.appController.selectedTabIndex == 3
                  ? null
                  :
              CustomAppBar(roleId: _roleId),
              resizeToAvoidBottomInset: true,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              floatingActionButton: !_isDataLoaded
                  ? const SizedBox.shrink()
                  : Obx(() {
                if (app.appController.selectedTabIndex == 1) {
                  return floatingButton(context);
                }
                return const SizedBox.shrink();
              }),
              // ✅ Hide BottomBar when on POS tab (index 3)
              bottomNavigationBar:
              // app.appController.selectedTabIndex == 3
              //     ? null :
              _buildBottomBar(),
              body: _isDataLoaded ? _buildBody() : Center(
                  child: Lottie.asset(
                    'assets/animations/burger.json',
                    width: 150,
                    height: 150,
                    repeat: true,
                  ))
          )),
    );
  }

  Widget floatingButton(BuildContext context) {
    if (_roleId != 1 && (_storeType == '1' || _storeType == '2')) {
      return const SizedBox.shrink();
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final fabSize = isLandscape ? 50.0 : 55.0;

    return Container(
      height: fabSize,
      width: fabSize,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(27.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27.5),
          onTap: () {
            if (app.appController.selectedTabIndex == 1) {
              app.appController.triggerAddReservation.value =
              !app.appController.triggerAddReservation.value;
            }
          },
          child: const Center(
            child: AnimatedRotation(
              turns: 0.0,
              duration: Duration(milliseconds: 200),
              child: Icon(
                Icons.add,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildBottomBar() {
    if (!_isDataLoaded) {
      return const SizedBox.shrink();
    }
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    double bottomBarHeight = isLandscape
        ? (Platform.isIOS ? 100 : 80)
        : (Platform.isIOS ? 100 : 70);
    return Container(
      height: bottomBarHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        color: Colors.grey[100],
      ),
      child: BottomAppBar(
        color: appColor.white,
        child: Obx(() =>
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ItemBottomBar(
                  selected: app.appController.selectedTabIndex == 0,
                  icon: "assets/images/ic_order.svg",
                  iconHeight: isLandscape ? 18 : 20,
                  iconWidth: isLandscape ? 18 : 20,
                  name: 'order'.tr,
                  showBadge: app.appController.getPendingOrder > 0,
                  badgeValue: app.appController.getPendingOrder,
                  onPressed: () {
                    _openTab(0);
                  },
                ),
                  ItemBottomBar(
                    selected: app.appController.selectedTabIndex == 1,
                    icon: "assets/images/reserv.svg",
                    iconHeight: 20,
                    iconWidth: 20,
                    name: 'reserv'.tr,
                    showBadge: app.appController.getPendingReservations > 0,
                    badgeValue: app.appController.getPendingReservations,
                    onPressed: () {
                      _openTab(1);
                    },
                  ),
                ItemBottomBar(
                  selected: app.appController.selectedTabIndex == 2,
                  icon: "assets/images/reports-icon.svg",
                  iconHeight: 20,
                  iconWidth: 20,
                  name: 'reports'.tr,
                  onPressed: () {
                    _openTab(2);
                  },
                ),
                if (_storeType == '1')
                  ItemBottomBar(
                    selected: app.appController.selectedTabIndex == 3,
                    icon: "assets/images/pos.svg",
                    iconHeight: 20,
                    iconWidth: 20,
                    name: 'POS'.tr,
                    onPressed: () {
                      _openTab(3);
                    },
                  ),
              ],
            )),
      ),
    );
  }

  Widget _buildBody() {
    final bool isAdmin = _roleId == 1;
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        print("Page changedto: $index");
      },
      children: [
        KeepAlivePage(child: isAdmin ? const AdminOrder() : const OrderScreenNew()),
        KeepAlivePage(child: isAdmin ? const SuperAdminReservation() : const Reservation()),
        KeepAlivePage(child: isAdmin ? const SuperAdminReport() : const ReportScreen()),
        if (_storeType == '1')
          KeepAlivePage(child: PosPortrait()),
      ],
    );
  }

  void _openTab(int index) {
    if (index == 3 && _storeType != '1') {
      return;
    }
    // ✅ First update the controller index immediately
    app.appController.onTabChanged(index);

    // ✅ ALWAYS set orientation FIRST, regardless of current page
    if (index == 3) {
      // POS tab - force portrait only (landscape disabled for now)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Other tabs - force portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    if (!_pageController.hasClients) {
      print("PageController not ready yet. Scheduling navigation to tab $index");
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _openTab(index);
        }
      });
      return;
    }

    print("Switching to Tab : $index");
    _pageController.jumpToPage(index);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (index == 2) {
        app.appController.reportRefreshTrigger.refresh();
      }
      if (index == 3 && mounted) {
        setState(() {});
      }
    });
  }
}