import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_receiver/models/Store.dart';
import 'package:food_receiver/ui/Invoice/invoices.dart';
import 'package:food_receiver/ui/Notification/notification.dart';
import 'package:food_receiver/ui/PostCode/postcode.dart';
import 'package:food_receiver/ui/Setting/PrinterSettingsScreen.dart';
import 'package:food_receiver/ui/Setting/change_password.dart';
import 'package:food_receiver/ui/home_screen.dart';

import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/databse_helper.dart';
import '../api/Socket/socket_service.dart';
import '../api/repository/api_repository.dart';
import '../constants/constant.dart';
import '../ui/Allergy/add_allergy.dart';
import '../ui/Allergy/item_allergy.dart';
import '../ui/Category Availability/category_management.dart';
import '../ui/Coupon/coupons.dart';
import '../ui/Customer/store_customer.dart';
import '../ui/Delivery Zone/delivery_zone.dart';
import '../ui/Discount/discount.dart';
import '../ui/Login/LoginScreen.dart';
import '../ui/Products/Category/category.dart';
import '../ui/Products/Group Item/group_item.dart';
import '../ui/Products/Product/products.dart';
import '../ui/Products/Topping/topping_group.dart';
import '../ui/Products/Topping/toppings.dart';
import '../ui/Products/product_group/product_group.dart';
import '../ui/StoreTiming/delivery_pickup_timing.dart';
import '../ui/StoreTiming/store_timing.dart';
import '../ui/SuperAdmin/device_status.dart';
import '../ui/Tax MAnagement/taxmanagement.dart';
import '../utils/log_util.dart';
import '../utils/my_application.dart';

class CustomDrawer extends StatefulWidget {
  final Function(int) onSelectTab;

  const CustomDrawer({super.key, required this.onSelectTab});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late SharedPreferences sharedPreferences;
  String? storeName;
  bool isMenuExpanded = false;
  bool isAllergyExpanded = false;
  bool isToppingExpanded = false;
  String? _storeType;
  int? _roleId;
  bool _isStoreDataFetched = false;
  @override
  initState() {
    initVar();
    super.initState();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

    // ✅ Check if data already fetched in this session
    if (_isStoreDataFetched) {
      print("⏭️ Store data already fetched, skipping API call");
      return;
    }

    if (storeID != null && storeID.isNotEmpty) {
      // ✅ First try to get from SQLite cache
      String? cachedStoreName = await DatabaseHelper().getStoreName(storeID);

      if (cachedStoreName != null && cachedStoreName.isNotEmpty) {
        // Show cached data immediately
        if (mounted) {
          setState(() {
            storeName = cachedStoreName;
            _isStoreDataFetched = true; // ✅ Mark as fetched
            print("✅ StoreName from SQLite Cache: $storeName");
          });
        }

        // ✅ If cache exists, NO API CALL
        print("🚫 Cache found, skipping API call");
      } else {
        // ✅ Only call API if NO cache exists
        if (bearerKey != null) {
          print("📡 No cache found, calling API...");
          await getStoredta(bearerKey);
        }
      }
    }

    final arguments = Get.arguments;
    int? roleFromArgs = (arguments != null && arguments['roleId'] != null)
        ? arguments['roleId'] as int
        : null;
    int? roleFromPrefs = sharedPreferences.getInt(valueShared_ROLE_ID);

    if (mounted) {
      setState(() {
        _storeType = sharedPreferences.getString(valueShared_STORE_TYPE);
        _roleId = roleFromArgs ?? roleFromPrefs;
      });
    }
  }

  Future<void> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreData(bearerKey, storeID!);

      Store store = result;

      // ✅ Save to SQLite (only id and name)
      if (store.name != null && store.name!.isNotEmpty) {
        await DatabaseHelper().saveStore(storeID, store.name!);

        if (mounted) {
          setState(() {
            storeName = store.name.toString();
            _isStoreDataFetched = true; // ✅ Mark as fetched after API success
            print("✅ StoreName from API & saved to SQLite: $storeName");
          });
        }
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  bool _isOnHomeScreen() {
    // ✅ More reliable check for HomeScreen
    return Get.currentRoute == '/HomeScreen' ||
        Get.currentRoute == '/' ||
        context.widget.runtimeType.toString().contains('HomeScreen');
  }

  void _navigateToHomeScreenTab(int tabIndex) {
    print("🎯 Drawer navigation to tab: $tabIndex");
    print("📍 Current route: ${Get.currentRoute}");

    // ✅ Close drawer first
    Navigator.pop(context);

    // ✅ Handle orientation BEFORE navigation
    if (tabIndex == 3) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // ✅ REMOVE the Future.delayed - call immediately
    // Check if currently on HomeScreen
    bool isCurrentlyOnHomeScreen = Get.currentRoute == '/HomeScreen' ||
        Get.currentRoute == '/' ||
        Get.currentRoute.isEmpty;

    if (isCurrentlyOnHomeScreen) {
      print("✅ Already on HomeScreen - switching to tab $tabIndex");
      // ✅ Call the tab switcher IMMEDIATELY
      widget.onSelectTab(tabIndex);
    } else {
      print("🔄 Not on HomeScreen (current: ${Get.currentRoute}) - navigating with initialTab: $tabIndex");
      // ✅ Navigate to HomeScreen with the tab
      Get.offAll(
            () => const HomeScreen(),
        arguments: {'initialTab': tabIndex},
        transition: Transition.noTransition,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      storeName == null || storeName!.isEmpty ?
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Lottie.asset(
                          'assets/animations/burger.json',
                          width: 30,
                          height: 30,
                          repeat: true,
                        ),
                      )
                          : Text(
                        storeName.toString(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _drawerItem('order'.tr,'assets/images/order.svg', onTap: () {
                    _navigateToHomeScreenTab(0);
                  }),
                  if (_roleId == 1 || _roleId == 5 || _storeType == '0' || _storeType == null)
                    _drawerItem('reserv'.tr,'assets/images/reserv.svg',
                        iconHeight: 14,
                        iconWidth: 20,
                        onTap: () {
                    _navigateToHomeScreenTab(1);
                  }),

                  _drawerItem('reports'.tr,'assets/images/report.svg', onTap: () {
                    _navigateToHomeScreenTab(2);
                  }),

                  _drawerItem('setting'.tr, 'assets/images/settings.svg', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const PrinterSettingsScreen());
                  }),

                  if (_roleId != 5) _expandableProductItem(),

                  if (_roleId != 5 && _storeType != '2')
                    _drawerItem('store'.tr,'assets/images/store.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const StoreTiming());
                    }),

                  if (_roleId != 5)
                    _drawerItem('postcode'.tr,'assets/images/postcode.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const Postcode());
                    }),

                  if (_roleId != 5)
                    _drawerItem('delivery_zone'.tr,'assets/images/postcode.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const DeliveryZone());
                    }),

                  if (_roleId != 5)
                    _drawerItem('time_plans'.tr,'assets/images/delivery_time.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const DeliveryPickupTiming());
                    }),

                  if (_roleId != 5)
                    _drawerItem('device_status'.tr,'assets/images/device.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const DeviceStatusScreen());
                    }),

                  _drawerItem('windows'.tr,'assets/images/device.svg', onTap: () {
                    Navigator.of(context).pop();
                    final sid = sharedPreferences.getString(valueShared_STORE_KEY);
                    Get.to(() => NotificationScreen(storeId: sid?.isNotEmpty == true ? sid : null));
                  }),
                  _drawerItem('customer'.tr,'assets/images/customer.svg', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const StoreCustomer(),
                        routeName: '/StoreCustomer');
                  }),
                  _drawerItem('invoices'.tr,'assets/images/invoice.svg', onTap: () {
                    Navigator.of(context).pop();
                    Get.to(() => const Invoices(),
                    );
                  }),
                  if (_roleId != 5)
                    _drawerItem('change_password'.tr,'assets/images/password.svg', onTap: () {
                      Navigator.of(context).pop();
                      Get.to(() => const ChangePassword());
                    }),
                  // _drawerItem('POS'.tr,'assets/images/pos.svg', onTap: () {
                  //   Navigator.pop(context);
                  //  widget.onSelectTab(3);
                  // }),
                  //
                  // _drawerItem('POS PORTRAIT'.tr,'assets/images/coupon.svg',
                  //     iconHeight: 30,
                  //     iconWidth: 20,
                  //     onTap: () {
                  //   Navigator.of(context).pop();
                  //   Get.to(() => const PosPortrait());
                  // }),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_roleId != 1 && _roleId != 5)
                  Container(
                    child: _drawerItem('logout'.tr,'assets/images/logout.svg', onTap: () async {
                      var bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
                     logutAPi(bearerKey);
                    }),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text('${'version'.tr}: 3.0(1)', style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 15
                  ),),
                ),
                const SizedBox(
                  height: 60,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(String title, String svgPath, {
    required VoidCallback onTap,
    double? iconHeight,
    double? iconWidth,
  }) {
    return ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: onTap,
        dense: true,
        leading: SvgPicture.asset(
          svgPath,
          color: const Color(0xff757B8F),
          height: iconHeight ?? 20,
          width: iconWidth ?? 20,
        ),
        //contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        visualDensity: VisualDensity.compact
    );
  }

  Future<void> logutAPi(String? bearerKey) async {
    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );
      print("🚪 Starting logout process...");

      final result = await ApiRepo().logoutAPi(bearerKey);
      print("✅ Logout API successful");

      await _disconnectSocket();

      // ✅ Clear SQLite database
      await DatabaseHelper().clearAllStores();
      await DatabaseHelper().clearAllNotifications();
      await DatabaseHelper().clearAllData();

      // ✅ Reset flag
      setState(() {
        _isStoreDataFetched = false;
        storeName = null;
      });

      await _preserveUserIPData();
      await _forceCompleteLogoutCleanup();

      app.appController.clearOnLogout();
      await _forceBackgroundHandlerClearCache();

      Navigator.of(context).pop();
      Get.offAll(() => const LoginScreen());

      print("✅ Logout completed successfully");
    } catch (e) {
      Log.loga(title, "Logout Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> _disconnectSocket() async {
    try {
      print("🔌 Disconnecting socket...");
      // Assuming you have a socket service - adjust the class name accordingly
      SocketServices().disconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      print("✅ Socket disconnected");
    } catch (e) {
      print("⚠️ Error disconnecting socket: $e");
    }
  }

  Future<void> _preserveUserIPData() async {
    try {
      print("💾 Preserving IP data for current user...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentStoreId = prefs.getString(valueShared_STORE_KEY);

      if (currentStoreId != null && currentStoreId.isNotEmpty) {
        // Save current IP data with store ID prefix
        String userPrefix = "user_${currentStoreId}_";

        // Preserve local printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentIP = prefs.getString('printer_ip_$i');
          if (currentIP != null && currentIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_$i', currentIP);
            print("💾 Saved ${userPrefix}printer_ip_$i: $currentIP");
          }
        }

        // Preserve remote printer IPs
        for (int i = 0; i < 5; i++) {
          String? currentRemoteIP = prefs.getString('printer_ip_remote_$i');
          if (currentRemoteIP != null && currentRemoteIP.isNotEmpty) {
            await prefs.setString('${userPrefix}printer_ip_remote_$i', currentRemoteIP);
            print("💾 Saved ${userPrefix}printer_ip_remote_$i: $currentRemoteIP");
          }
        }

        // Preserve selected indices
        int? selectedIndex = prefs.getInt('selected_ip_index');
        if (selectedIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_index', selectedIndex);
        }

        int? selectedRemoteIndex = prefs.getInt('selected_ip_remote_index');
        if (selectedRemoteIndex != null) {
          await prefs.setInt('${userPrefix}selected_ip_remote_index', selectedRemoteIndex);
        }

        // Preserve toggle settings
        bool? autoOrderAccept = prefs.getBool('auto_order_accept');
        if (autoOrderAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_accept', autoOrderAccept);
        }

        bool? autoOrderPrint = prefs.getBool('auto_order_print');
        if (autoOrderPrint != null) {
          await prefs.setBool('${userPrefix}auto_order_print', autoOrderPrint);
        }

        bool? autoRemoteAccept = prefs.getBool('auto_order_remote_accept');
        if (autoRemoteAccept != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_accept', autoRemoteAccept);
        }

        bool? autoRemotePrint = prefs.getBool('auto_order_remote_print');
        if (autoRemotePrint != null) {
          await prefs.setBool('${userPrefix}auto_order_remote_print', autoRemotePrint);
        }

        print("✅ IP data preserved for store: $currentStoreId");
      } else {
        print("⚠️ No store ID found, cannot preserve IP data");
      }
    } catch (e) {
      print("❌ Error preserving IP data: $e");
    }
  }

  Future<void> _forceCompleteLogoutCleanup() async {
    try {
      print("🧹 Starting complete logout cleanup...");
      for (int attempt = 0; attempt < 3; attempt++) {
        print("🔄 Cleanup attempt ${attempt + 1}/3");
        await DatabaseHelper().clearAllStores();
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<String> keysToRemove = [
          valueShared_BEARER_KEY,
          valueShared_STORE_KEY,

          'super_admin_username',
          'super_admin_password',


          'printer_ip_backup',
          'printer_ip_0_backup',
          'last_save_timestamp',

          'printer_ip_0',
          'printer_ip_remote_0',
          'selected_ip_index',
          'selected_ip_remote_index',

          'auto_order_accept',
          'auto_order_print',
          'auto_order_remote_accept',
          'auto_order_remote_print',

          'manual_override',
          'manual_start',
        ];

        for (String key in keysToRemove) {
          await prefs.remove(key);
          await Future.delayed(const Duration(milliseconds: 20));
          print("🗑️ Removed: $key");
        }

        // ✅ Also clear all printer IP keys (0-4) to ensure complete cleanup
        for (int i = 0; i < 5; i++) {
          await prefs.remove('printer_ip_$i');
          await prefs.remove('printer_ip_remote_$i');
        }

        // ✅ Force multiple reloads to ensure changes are committed
        await prefs.reload();
        await Future.delayed(const Duration(milliseconds: 100));
        await prefs.reload();
        await Future.delayed(const Duration(milliseconds: 100));

        // ✅ Verify cleanup for this attempt
        String? testToken = prefs.getString(valueShared_BEARER_KEY);
        String? testBackupIp = prefs.getString('printer_ip_backup');
        if (testToken == null && testBackupIp == null) {
          print("✅ Cleanup attempt ${attempt + 1}: SUCCESS");
        } else {
          print("⚠️ Cleanup attempt ${attempt + 1}: Token still exists, retrying...");
        }
      }

      // ✅ Final verification
      SharedPreferences finalPrefs = await SharedPreferences.getInstance();
      await finalPrefs.reload();
      String? finalToken = finalPrefs.getString(valueShared_BEARER_KEY);
      String? finalBackupIp = finalPrefs.getString('printer_ip_backup');

      if (finalToken == null && finalBackupIp == null) {
        print("✅ Complete logout cleanup SUCCESS - All tokens removed");
      } else {
        print("❌ Logout cleanup FAILED - Token still exists: ${finalToken!.substring(0, 10)}...");
      }

    } catch (e) {
      print("❌ Error in complete logout cleanup: $e");
    }
  }

  Future<void> _forceBackgroundHandlerClearCache() async {
    try {
      print("🔄 Forcing background handler cache clear...");

      // Additional delay to ensure background handler gets the cleared preferences
      await Future.delayed(const Duration(milliseconds: 300));

      // Create a test instance to verify background handler will get null token
      SharedPreferences testPrefs = await SharedPreferences.getInstance();
      await testPrefs.reload();

      String? testToken = testPrefs.getString(valueShared_BEARER_KEY);
      if (testToken == null) {
        print("✅ Background handler cache should now be cleared");
      } else {
        print("❌ Background handler cache clear failed - token still exists");
      }

    } catch (e) {
      print("❌ Error clearing background handler cache: $e");
    }
  }

  Widget _expandableProductItem() {
    return Column(
      children: [
        ListTile(
          leading: SvgPicture.asset('assets/images/product.svg',color: const Color(0xff757B8F),height: 20,width: 25,),
          title: Row(
            children: [
              Text('menu'.tr, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Icon(
                isMenuExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
            ],
          ),
          onTap: () {
            setState(() {
              isMenuExpanded = !isMenuExpanded;
            });
          },
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Add this line
            visualDensity: VisualDensity.compact,
        ),
        if (isMenuExpanded) ...[
          _subDrawerItem(
            'discount'.tr,
           // svgPath: 'assets/images/discount.svg',
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const Discount());
            },
          ),
          _subDrawerItem('availability'.tr,
              //  svgPath: 'assets/images/discount.svg',
                onTap: () {
            Navigator.of(context).pop();
            Get.to(() => const CategoryManagement());
          }),
          _subDrawerItem('manage'.tr,
              //svgPath: 'assets/images/tax.svg',
              onTap: () {
            Navigator.of(context).pop();
            Get.to(() => const Taxmanagement());
          }),
          _subDrawerItem('coupon'.tr,
             // svgPath: 'assets/images/coupon.svg',
              iconHeight: 30,
              iconWidth: 20,
              onTap: () {
            Navigator.of(context).pop();
            Get.to(() => const Coupon());
          }),
          _subDrawerItem('category'.tr, onTap: () {
            Navigator.of(context).pop();
            // Use named route for proper route detection
            Get.to(() => const Category(), routeName: '/Category');
          }),
          _subDrawerItem('product'.tr, onTap: () {
            Navigator.of(context).pop();
            // ✅ Save current tab index before navigating
            int currentTab = app.appController.selectedTabIndex;

            Get.to(
                  () => const Products(),
              routeName: '/Products',
            )?.then((_) {
              // ✅ When returning from Products, restore tab index
              if (Get.currentRoute == '/HomeScreen') {
                app.appController.onTabChanged(currentTab);
              }
            });
          }),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child:  ListTile(
              leading: SvgPicture.asset('assets/images/topping-icon.svg',
                color: const Color(0xff757B8F),height: 15,width: 25,),
              title: Row(
                children: [
                  Text('topping'.tr,  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),),
                  const Spacer(),
                  Icon(
                    isToppingExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  isToppingExpanded = !isToppingExpanded;
                });
              },
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if(isToppingExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                children: [
                  if (_storeType != '2')
                    _subDrawerItem('add_toppings'.tr, onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to Toppings screen
                      Get.to(() => const ToppingsScreen());
                    }),
                  if (_storeType != '2')
                    _subDrawerItem('topping_group'.tr, onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to Topping Group screen
                      Get.to(() => const ToppingGroup());
                    }),
                  if (_storeType != '2')
                    _subDrawerItem('group'.tr, onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to Group Item screen
                      Get.to(() => const GroupItem());
                    }),
                  if (_storeType != '2')
                    _subDrawerItem('product_group'.tr, onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to Product Groups screen
                      Get.to(() => const ProductGroup());
                    }),
                ],
              ),)
          ],
         Padding(padding: const EdgeInsets.only(left: 15),
           child:  ListTile(
             leading: SvgPicture.asset('assets/images/allergy.svg',
               color: const Color(0xff757B8F),height: 20,width: 25,),
             title: Row(
               children: [
                 Text('allergy'.tr,  style: const TextStyle(
                   fontSize: 14,
                   fontWeight: FontWeight.w400,
                 ),),
                 const Spacer(),
                 Icon(
                   isAllergyExpanded ? Icons.expand_less : Icons.expand_more,
                   color: Colors.grey[600],
                 ),
               ],
             ),
             onTap: () {
               setState(() {
                 isAllergyExpanded = !isAllergyExpanded;
               });
             },
             dense: true,
             contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
             visualDensity: VisualDensity.compact,
           ),
         ),
          if(isAllergyExpanded) ...[
            Padding(padding: const EdgeInsets.only(left: 10),
              child: _subDrawerItem('add_allergy'.tr, onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const AddAllergy());
              }),),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child:  _subDrawerItem('item_allergy'.tr, onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const ItemAllergy());
              }),
            )
          ]
        ],
      ],
    );
  }

  Widget _subDrawerItem(String title,
      {String?svgPath,
    required VoidCallback onTap, double? iconHeight,
    double? iconWidth,}) {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0),
      child: ListTile(
        title: Text(
         '- $title',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w400,
          ),
        ),
        onTap: onTap,
        leading: svgPath == null
            ? null
            : SvgPicture.asset(
          svgPath,
          color: const Color(0xff757B8F),
          height: iconHeight ?? 20,
          width: iconWidth ?? 20,
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Add this line
        visualDensity: VisualDensity.compact, //
      ),
    );
  }
}