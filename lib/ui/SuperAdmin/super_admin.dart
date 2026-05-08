import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_receiver/ui/SuperAdmin/all_store_reservation.dart';
import 'package:food_receiver/ui/SuperAdmin/settings.dart';
import 'package:food_receiver/ui/SuperAdmin/superAdminOrderDetail.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Database/databse_helper.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/all_admin_order_response_model.dart';
import '../../models/get_admin_report_response_model.dart';
import '../Login/LoginScreen.dart';
import '../home_screen.dart';
import 'device_status.dart';

class SuperAdmin extends StatefulWidget {
  const SuperAdmin({super.key});

  @override
  State<SuperAdmin> createState() => _SuperAdminState();
}

class _SuperAdminState extends State<SuperAdmin> {
  bool isLoading = false;
  List<AllOrderAdminResponseModel> orderList = [];
  List<AllOrderAdminResponseModel> filteredOrderList = [];
  List<Reports> filteredStoreList = [];
  TextEditingController searchController = TextEditingController();
  List<Reports>? reports=[];
  int currentOffset = 0;
  int limit = 20;
  bool isLoadingMore = false;
  bool isLoadingPrevious = false;
  bool hasMoreOrders = true;
  bool hasPreviousOrders = true;
  ScrollController orderScrollController = ScrollController();
  DateTime? _lastScrollTime;
  bool isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isHistoryMode = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SuperAdminController>()) {
      Get.put(SuperAdminController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getAllStoreReport();
      getAllOrderAdmin();
      final controller = Get.find<SuperAdminController>();
      controller.setRefreshCallback(refreshAllData);
    });

    searchController.addListener(_filterData);
    orderScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final now = DateTime.now();
    if (_lastScrollTime != null &&
        now.difference(_lastScrollTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastScrollTime = now;

    if (orderScrollController.position.pixels >=
        orderScrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMoreOrders) {
      _loadMoreOrders();
    }

    if (orderScrollController.position.pixels <= 200 &&
        !isLoadingPrevious &&
        hasPreviousOrders &&
        currentOffset > 0) {
      _loadPreviousOrders();
    }
  }

  Future<void> refreshAllData() async {
    if (isRefreshing) {
      print('ðŸ"„ Already refreshing, skipping...');
      return;
    }

    setState(() {
      isRefreshing = true;
    });

    try {
      print('ðŸ"„ Manual refresh triggered');

      // Reset pagination
      currentOffset = 0;
      hasMoreOrders = true;
      hasPreviousOrders = true;

      // Clear existing data
      orderList.clear();
      filteredOrderList.clear();

      // Fetch fresh data
      await Future.wait([
        getAllOrderAdmin(),
       getAllStoreReport()
      ]);

      print('âœ… Refresh completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orders refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('âŒ Refresh error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh orders'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> onNewOrderReceived() async {
    print('ðŸ"" Super Admin - New order notification received');
    await refreshAllData();
  }

  Future<void> _loadPreviousOrders() async {
    if (isLoadingPrevious || !hasPreviousOrders || currentOffset <= 0) return;

    setState(() {
      isLoadingPrevious = true;
    });

    try {
      int previousOffset = currentOffset - limit;
      if (previousOffset < 0) previousOffset = 0;

      List<AllOrderAdminResponseModel> previousOrders =
      await CallService().getAllAdminOrder(
        limit: limit,
        offset: previousOffset,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        includePast: _isHistoryMode,
      );

      if (previousOrders.isEmpty) {
        setState(() {
          hasPreviousOrders = false;
          isLoadingPrevious = false;
        });
        return;
      }

      double previousScrollPosition = orderScrollController.position.pixels;

      setState(() {
        Set<int> existingIds = orderList.map((o) => o.id ?? 0).toSet();
        List<AllOrderAdminResponseModel> uniqueOrders =
        previousOrders.where((order) => !existingIds.contains(order.id)).toList();

        if (uniqueOrders.isNotEmpty) {
          orderList.insertAll(0, uniqueOrders);
          currentOffset = previousOffset;
          _filterData();
        } else {
          hasPreviousOrders = false;
        }
        isLoadingPrevious = false;
      });

      if (previousScrollPosition > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (orderScrollController.hasClients) {
            orderScrollController.jumpTo(previousScrollPosition + 300);
          }
        });
      }
    } catch (e) {
      print('Error loading previous orders: $e');
      setState(() {
        isLoadingPrevious = false;
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (isLoadingMore || !hasMoreOrders) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      int nextOffset = currentOffset + limit;

      List<AllOrderAdminResponseModel> newOrders =
      await CallService().getAllAdminOrder(
        limit: limit,
        offset: nextOffset,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        includePast: _isHistoryMode,
      );

      setState(() {
        if (newOrders.isEmpty) {
          hasMoreOrders = false;
        } else if (newOrders.length < limit) {
          hasMoreOrders = false;
        }

        if (newOrders.isNotEmpty) {
          Set<int> existingIds = orderList.map((o) => o.id ?? 0).toSet();
          List<AllOrderAdminResponseModel> uniqueOrders =
          newOrders.where((order) => !existingIds.contains(order.id)).toList();

          if (uniqueOrders.isNotEmpty) {
            orderList.addAll(uniqueOrders);
            currentOffset = nextOffset;
            _filterData();
          } else {
            hasMoreOrders = false;
          }
        }
        isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more orders: $e');
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text('Failed to load more orders. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }

  Future<void> _pickDateRange() async {
    final today = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'Select Start Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
        child: child!,
      ),
    );
    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: today,
      helpText: 'Select End Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)),
        child: child!,
      ),
    );
    if (end == null) return;

    final today0 = DateTime(today.year, today.month, today.day);
    final start0 = DateTime(start.year, start.month, start.day);
    final end0 = DateTime(end.year, end.month, end.day);

    setState(() {
      _startDate = start;
      _endDate = end;
      _isHistoryMode = start0.isBefore(today0) || end0.isBefore(today0);
      orderList.clear();
      filteredOrderList.clear();
      currentOffset = 0;
      hasMoreOrders = true;
    });
    await getAllOrderAdmin();
  }

  Future<void> _resetToToday() async {
    final today = DateTime.now();
    setState(() {
      _startDate = today;
      _endDate = today;
      _isHistoryMode = false;
      orderList.clear();
      filteredOrderList.clear();
      currentOffset = 0;
      hasMoreOrders = true;
    });
    await getAllOrderAdmin();
  }

  @override
  void dispose() {
    searchController.dispose();
    orderScrollController.dispose();

    // âœ… Clear callback
    try {
      final controller = Get.find<SuperAdminController>();
      controller.refreshCallback = null;
    } catch (e) {}

    super.dispose();
  }

  void _filterData() {
    String query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredStoreList = reports!;
        filteredOrderList = orderList;
      } else {
        // Filter stores
        filteredStoreList = reports!.where((store) {
          String storeName = store.storeName?.toLowerCase() ?? '';  // Changed from reports.name
          String storeId = store.storeId?.toString() ?? '';  // Changed from store.id

          return storeName.contains(query) || storeId.contains(query);
          // Removed storeAddress as it doesn't exist in Reports model
        }).toList();

        // Filter orders - keep as is
        filteredOrderList = orderList.where((order) {
          String orderNumber = order.orderNumber?.toString().toLowerCase() ?? '';
          String storeName = order.storeName?.toLowerCase() ?? '';
          String customerName = order.shippingAddress?.customerName?.toLowerCase() ??
              order.guestShippingJson?.customerName?.toLowerCase() ?? '';
          String phone = order.shippingAddress?.phone?.toLowerCase() ??
              order.guestShippingJson?.phone?.toLowerCase() ?? '';
          String amount = order.payment?.amount?.toString() ?? '';

          return orderNumber.contains(query) ||
              storeName.contains(query) ||
              customerName.contains(query) ||
              phone.contains(query) ||
              amount.contains(query);
        }).toList();
      }
    });
  }

  Map<String, Color> getStoreColors(int? storeId) {
    switch (storeId) {
      case 12:
        return {
          'border': const Color(0xff029543),
          'background':  const Color(0xffEBFAF2),
          'nameColor':  const Color(0xff029543),
        };
      case 13:
        return {
          'border': const Color(0xffE4121E),
          'background': const Color(0xffFCF6F7),
          'nameColor': const Color(0xffE4121E),
        };
      case 14:
        return {
          'border': const Color(0xff841D1C),
          'background': const Color(0xffF6EDED),
          'nameColor': const Color(0xff841D1C),
        };
      case 15:
        return {
          'border': const Color(0xff023047),
          'background': const Color(0xffFAFDFF),
          'nameColor': const Color(0xff023047),
        };
      case 16:
        return {
          'border': const Color(0xff624BA1),
          'background': const Color(0x0ffdfcff),
          'nameColor': const Color(0xff624BA1),
        };
      case 18:
        return {
          'border': const Color(0xffE0D2AA),
          'background': const Color(0xffFAF3E0),
          'nameColor': const Color(0xffE64425),
        };
      case 19:
        return {
          'border': const Color(0xffF9CC46),
          'background': const Color(0xffFDFAF1),
          'nameColor': const Color(0xff029447),
        };
      case 20:
        return {'border': const Color(0xffE31E22), 'background': const Color(0xffFFDCDD), 'nameColor': const Color(0xffE31E22)};
      case 21:
        return {'border': const Color(0xff0D9488), 'background': const Color(0xffF0FDFA), 'nameColor': const Color(0xff0D9488)};
      case 22:
        return {'border': const Color(0xffEA580C), 'background': const Color(0xffFFF7ED), 'nameColor': const Color(0xffEA580C)};
      case 23:
        return {'border': const Color(0xff4338CA), 'background': const Color(0xffEEF2FF), 'nameColor': const Color(0xff4338CA)};
      case 24:
        return {'border': const Color(0xffDB2777), 'background': const Color(0xffFDF2F8), 'nameColor': const Color(0xffDB2777)};
      case 25:
        return {'border': const Color(0xff4D7C0F), 'background': const Color(0xffF7FEE7), 'nameColor': const Color(0xff4D7C0F)};
      case 26:
        return {'border': const Color(0xff0E7490), 'background': const Color(0xffECFEFF), 'nameColor': const Color(0xff0E7490)};
      case 27:
        return {'border': const Color(0xffBE123C), 'background': const Color(0xffFFF1F2), 'nameColor': const Color(0xffBE123C)};
      case 28:
        return {'border': const Color(0xffB45309), 'background': const Color(0xffFEF3C7), 'nameColor': const Color(0xffB45309)};
      case 29:
        return {'border': const Color(0xff047857), 'background': const Color(0xffECFDF5), 'nameColor': const Color(0xff047857)};
      case 30:
        return {'border': const Color(0xff6D28D9), 'background': const Color(0xffF5F3FF), 'nameColor': const Color(0xff6D28D9)};
      case 31:
        return {'border': const Color(0xff0369A1), 'background': const Color(0xffF0F9FF), 'nameColor': const Color(0xff0369A1)};
      case 32:
        return {'border': const Color(0xffA21CAF), 'background': const Color(0xffFDF4FF), 'nameColor': const Color(0xffA21CAF)};
      case 33:
        return {'border': const Color(0xff78350F), 'background': const Color(0xffFDF6EC), 'nameColor': const Color(0xff78350F)};
      case 34:
        return {'border': const Color(0xff475569), 'background': const Color(0xffF8FAFC), 'nameColor': const Color(0xff475569)};
      default:
        return {'border': const Color(0xffE0D2AA), 'background': Colors.white, 'nameColor': const Color(0xffE64425)};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Sticky Header Section
          Container(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Search Box and Logout
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Search stores, orders, names, phones...',
                              hintStyle: const TextStyle(
                                  color: Color(0xffAEAEAE),
                                  fontSize: 12,
                                  fontFamily: 'Mulish-Italic-VariableFont_wght',
                                  fontWeight: FontWeight.w300),
                              prefixIcon: Image.asset('assets/images/search.png'),
                              suffixIcon: searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 5,),
                      GestureDetector(
                        onTap: (){
                          Get.to(()=>Settings());
                        },
                        child: Container(padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.lightGreen,width: 1),
                            borderRadius: BorderRadius.circular(8)
                          ),
                            child: Icon(Icons.settings_outlined,color: Colors.green,)),
                      ), SizedBox(width: 5,),
                      GestureDetector(
                          onTap: () {
                            showLogoutConfirmation(context);
                          },
                          child: Container(padding: EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.lightGreen,width: 1),
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.logout, color: Colors.green)))
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 12,right: 12,bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: (){
                              Get.to(()=>const DeviceStatusScreen());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black,width: 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.print_outlined,color: Colors.green,size: 20,),
                                  SizedBox(width: 5,),
                                  Text('Status',),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10,),
                          InkWell(
                            onTap: (){
                              Get.to(()=>AllStoreReservation());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black,width: 1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child:  Row(
                                children: [
                                 Image.asset('assets/images/reservationIcon.png',height: 15,width: 15,),
                                  SizedBox(width: 5,),
                                  Text('Reservation',),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10,),
                          GestureDetector(
                            onTap: isRefreshing ? null : refreshAllData,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isRefreshing ? Colors.grey : Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isRefreshing)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.refresh, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRefreshing ? 'Refreshing...' : 'Refresh',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: Text(
                      'Found ${filteredStoreList.length} store(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                filteredStoreList.isEmpty && searchController.text.isNotEmpty
                    ? Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No stores found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    : RepaintBoundary(
                      child: SizedBox(
                                        height: 150,
                                        child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filteredStoreList.length,
                      itemBuilder: (context, index) {
                        var store = filteredStoreList[index];
                        return InkWell(
                          onTap: () async {
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString(valueShared_STORE_KEY,
                                store.storeId.toString());
                      
                            await Future.delayed(const Duration(milliseconds: 50));
                      
                            Get.to(() => const HomeScreen(), arguments: {
                              'storeId': store.storeId.toString(),
                              'roleId': 1,
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  width: 1,
                                  color: getStoreColors(store.storeId)['border']!
                              ),
                              color: getStoreColors(store.storeId)['background']!,
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID : ${store.storeId}',  // Changed from store.id
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Mulish'
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width*0.28,
                                      child: Text('${store.storeName}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Mulish',
                                            color: getStoreColors(store.storeId)['nameColor']!  // Changed from store.id
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (store.report != null)
                                  Text(
                                    'Orders : ${store.report!.totalOrders ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                Text(
                                    'Sale : ${store.report!.totalSales ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                                        ),
                                      ),
                    ),
                if (searchController.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          'Found ${filteredOrderList.length} order(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                  ),
                // ── History / Today row ───────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black38,width: 2)
                          ),
                          child: Row(
                            children: [
                              Text(
                                _isHistoryMode
                                    ? '${DateFormat('dd MMM').format(_startDate)} – ${DateFormat('dd MMM yy').format(_endDate)}'
                                    : 'History',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _isHistoryMode ? Colors.orange.shade700 : const Color(0xff1F1E1E),
                                ),
                              ),
                              const SizedBox(width: 5),
                              SvgPicture.asset('assets/images/dropdown.svg', height: 5, width: 11),
                            ],
                          ),
                        ),
                      ),
                      if (_isHistoryMode)
                        GestureDetector(
                          onTap: _resetToToday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: refreshAllData,
                color: Colors.green,
                backgroundColor: Colors.white,
                child: Scrollbar(
                  controller: orderScrollController,
                  thumbVisibility: true,
                  thickness: 8,
                  radius: const Radius.circular(10),
                  interactive: true,
                  child: ListView.builder(
                controller: orderScrollController,
                padding: EdgeInsets.zero,
                itemCount: filteredOrderList.length +
                    (isLoadingMore ? 1 : 0) +
                    (isLoadingPrevious ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0 && isLoadingPrevious) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  int adjustedIndex = isLoadingPrevious ? index - 1 : index;

                  if (adjustedIndex == filteredOrderList.length &&
                      isLoadingMore) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (filteredOrderList.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(top: 50),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var order = filteredOrderList[adjustedIndex];
                  DateTime dateTime =
                  DateTime.parse(order.createdAt.toString());
                  String time = DateFormat('hh:mm a').format(dateTime);
                  String guestAddress =
                      order.guestShippingJson?.zip?.toString() ?? '';
                  String guestName = order.guestShippingJson?.customerName
                      ?.toString() ??
                      '';
                  String guestPhone =
                      order.guestShippingJson?.phone?.toString() ?? '';

                  Color getContainerColor() {
                    switch (order.approvalStatus) {
                      case 2:
                        return const Color(0xffEBFFF4);
                      case 3:
                        return const Color(0xffFFEFEF);
                      case 1:
                        return Colors.white;
                      default:
                        return Colors.white;
                    }
                  }

                  return GestureDetector(
                    onTap: (){
                      Get.to(()=>SuperAdminOrderDetail(order));
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: getContainerColor(),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: (order.approvalStatus == 2)
                              ? const Color(0xffC3F2D9)
                              : (order.approvalStatus == 3)
                              ? const Color(0xffFFD0D0)
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.green,
                                    child: SvgPicture.asset(
                                      order.orderType == 1
                                          ? 'assets/images/ic_delivery.svg'
                                          : order.orderType == 2
                                          ? 'assets/images/ic_pickup.svg'
                                          : 'assets/images/ic_pickup.svg',
                                      height: 14,
                                      width: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width *
                                            0.6,
                                        child: Text(
                                          order.storeName.toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              fontFamily: "Mulish-Regular"),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: "Mulish",
                                      fontSize: 10,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Text(
                                  '${order.shippingAddress?.customerName ?? guestName ?? ""} / ${order.shippingAddress?.phone ?? guestPhone}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "Mulish",
                                      fontSize: 13),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${order.orderNumber != null ? 'order_number'.tr : 'Order ID'} : ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        fontFamily: "Mulish"),
                                  ),
                                  Text(
                                    '${order.orderNumber ?? order.id ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        fontFamily: "Mulish"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.payment != null
                                    ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
                                    : '${'currency'.tr} ${formatAmount(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontFamily: "Mulish",
                                    fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Text(
                                    getApprovalStatusText(order.approvalStatus),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontFamily: "Mulish-Regular",
                                        fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: getStatusColor(
                                        order.approvalStatus ?? 0),
                                    child: Icon(
                                      getStatusIcon(order.approvalStatus ?? 0),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ) ),
        ],
      ),
    );
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.visibility;
      case 2:
        return Icons.check;
      case 3:
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return "pending".tr;
      case 2:
        return "accepted".tr;
      case 3:
        return "decline".tr;
      default:
        return "Unknown";
    }
  }

  Future<void> getAllStoreReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );

      GetAdminReportResponseModel REPORT = await CallService().getAdminReportAllStore();

      setState(() {
       reports=REPORT.reports;
       filteredStoreList=reports!;
       print('AdminReport length is ${reports!.length}');
      });

      Get.back();
    } catch (e) {
      print('Error getting report : $e');
      setState(() {
        isLoading = false;
      });
      Get.back();
    }
  }

  Future<void> getAllOrderAdmin() async {
    setState(() {
      isLoading = true;
      currentOffset = 0;
      hasMoreOrders = true;
    });

    try {
      List<AllOrderAdminResponseModel> order = await CallService().getAllAdminOrder(
        limit: limit,
        offset: 0,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        includePast: _isHistoryMode,
      );

      setState(() {
        orderList = order;
        filteredOrderList = order;
        if (order.length < limit) {
          hasMoreOrders = false;
        }
        print('order length is ${orderList.length}');
        isLoading = false;
      });
    } catch (e) {
      print('Error getting order : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
              child: Lottie.asset(
                'assets/animations/burger.json',
                width: 150,
                height: 150,
                repeat: true,
              )),
        ),
        barrierDismissible: false,
      );

      // ✅ Get bearer key and call logout API
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? bearerKey = prefs.getString(valueShared_BEARER_KEY);

      if (bearerKey != null) {
        print("🚪 Calling logout API...");
        await ApiRepo().logoutAPi(bearerKey);
        print("✅ Logout API successful");
      }

      // ✅ Clear SQLite database
      await DatabaseHelper().clearAllStores();

      // Clear SharedPreferences
      await prefs.remove(valueShared_BEARER_KEY);
      await prefs.remove(valueShared_STORE_KEY);
      await prefs.remove(valueShared_ROLE_ID);
      await prefs.remove(valueShared_STORE_TYPE);
      await prefs.remove('auto_order_accept');
      await prefs.remove('auto_order_print');
      await prefs.remove('auto_order_remote_accept');
      await prefs.remove('auto_order_remote_print');

      for (int i = 0; i < 5; i++) {
        await prefs.remove('printer_ip_$i');
      }

      await prefs.reload();
      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.offAll(() => const LoginScreen());

      await Future.delayed(const Duration(milliseconds: 300));

      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
      }

      print("✅ Logout successful");
    } catch (e) {
      print("❌ Logout error: $e");

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      final context = Get.context;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  void showLogoutConfirmation(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  '${'are_sure'.tr}${'logout'.tr}?',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontFamily: 'Mulish'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 35,
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8E9AAF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      height: 35,
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE25454),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Get.back();
                          logout();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        child: Text(
                          'logout'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFED4C5C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }
}

class SuperAdminController extends GetxController {
  final RxBool isRefreshing = false.obs;
  Function? refreshCallback;

  void setRefreshCallback(Function callback) {
    refreshCallback = callback;
  }

  Future<void> triggerRefresh() async {
    if (refreshCallback != null) {
      await refreshCallback!();
    }
  }
}