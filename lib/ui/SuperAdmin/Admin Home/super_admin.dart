import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_svg/svg.dart';
import 'package:food_receiver/ui/SuperAdmin/Admin%20Home/all_store_reservation.dart';
import 'package:food_receiver/ui/SuperAdmin/Admin%20Home/settings.dart';
import 'package:food_receiver/ui/SuperAdmin/Admin%20Home/superAdminOrderDetail.dart';
import 'package:food_receiver/ui/SuperAdmin/drawer/store_config.dart';
import 'package:food_receiver/ui/SuperAdmin/drawer/store_status.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../Database/databse_helper.dart';
import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/payment_icon.dart';
import '../../../models/all_admin_order_response_model.dart';
import '../../../models/get_admin_report_response_model.dart';
import '../../Login/LoginScreen.dart';
import '../../home_screen.dart';
import 'V2 Reservation/all_store_reservationV2.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isHistoryMode = false;
  int _totalOrdersCount = 0;
  double _totalSalesAmount = 0.0;
  bool _isLoadingTotals = false;
  // Gradient header slides away while scrolling orders down, comes back on scroll up.
  bool _headerVisible = true;

  bool _onOrderScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final visible = n.direction == ScrollDirection.reverse
        ? false
        : n.direction == ScrollDirection.forward
            ? true
            : _headerVisible;
    if (visible != _headerVisible) setState(() => _headerVisible = visible);
    return false;
  }
  // Remove mode: long-press a store card, tap ✕ to hide that store (and its orders/totals) locally.
  bool _removeMode = false;
  final Set<int> _hiddenStoreIds = {};
  List<AllOrderAdminResponseModel> _totalsOrders = [];

  bool _isVorbestellen(String? deliveryTime) {
    if (deliveryTime == null || deliveryTime.isEmpty) return false;
    try {
      final deliveryDate = DateTime.parse(deliveryTime);
      final now = DateTime.now();
      return deliveryDate.year != now.year ||
          deliveryDate.month != now.month ||
          deliveryDate.day != now.day;
    } catch (_) {
      return false;
    }
  }
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
      currentOffset = 0;
      hasMoreOrders = true;
      hasPreviousOrders = true;

      await Future.wait([
        getAllOrderAdmin(),
        getAllStoreReport(showLoader: false).catchError((e) {
          print('Report refresh failed (non-critical): $e');
        }),
      ]);

      print('✅ Refresh completed');
    } catch (e) {
      print('❌ Refresh error: $e');
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
            content: Text('Failed to load more orders. Please try again.', style: const TextStyle(fontFamily: 'Sora')),
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
    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _DateRangePickerDialog(),
    );

    if (result == null) return;

    final start = result['start']!;
    final end = result['end']!;
    final today = DateTime.now();
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
    final visibleStores =
        (reports ?? []).where((s) => !_hiddenStoreIds.contains(s.storeId)).toList();
    final visibleOrders =
        orderList.where((o) => !_hiddenStoreIds.contains(o.storeId)).toList();

    setState(() {
      if (query.isEmpty) {
        filteredStoreList = visibleStores;
        filteredOrderList = visibleOrders;
      } else {
        // Filter stores
        filteredStoreList = visibleStores.where((store) {
          String storeName = store.storeName?.toLowerCase() ?? '';  // Changed from reports.name
          String storeId = store.storeId?.toString() ?? '';  // Changed from store.id

          return storeName.contains(query) || storeId.contains(query);
          // Removed storeAddress as it doesn't exist in Reports model
        }).toList();

        // Filter orders - keep as is
        filteredOrderList = visibleOrders.where((order) {
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

  // ── New UI (same look as the store screens) ───────────────────────────
  static const _kViolet = Color(0xFFA42BF0);
  static const _kPurple = Color(0xFF7B52F0);
  static const _kIndigo = Color(0xFF5B4FE8);
  static const _kBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_kViolet, _kPurple, _kIndigo],
  );
  static const _kHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D3DF0), Color(0xFF4F6DF7), Color(0xFFE5486F)],
  );
  static const _kPageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6EEFF), Color(0xFFF0EDFF), Color(0xFFEAEBFF)],
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'good_morning'.tr;
    if (h >= 12 && h < 17) return 'good_afternoon'.tr;
    if (h >= 17 && h < 21) return 'good_evening'.tr;
    return 'good_night'.tr;
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Icon(icon, size: 20, color: _kPurple),
      ),
    );
  }

  Widget _pill({required Widget icon, required String label, required VoidCallback? onTap, Color color = _kPurple, bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: filled ? color : color.withValues(alpha: 0.55), width: 1.1),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w700, color: filled ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Sora', fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontFamily: 'Sora', fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _storeCard(Reports store) {
    final colors = getStoreColors(store.storeId);
    return Stack(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onLongPress: () => setState(() => _removeMode = true),
          onTap: () async {
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(valueShared_STORE_KEY, store.storeId.toString());

            await Future.delayed(const Duration(milliseconds: 50));

            Get.to(() => const HomeScreen(), arguments: {
              'storeId': store.storeId.toString(),
              'roleId': 1,
            });
          },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.36,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors['border']!, width: 1.2),
              boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: colors['background'], borderRadius: BorderRadius.circular(6)),
                      child: Text('ID : ${store.storeId}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, fontFamily: 'Sora', color: colors['nameColor'])),
                    ),
                  ],
                ),
                Text('${store.storeName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Sora', color: colors['nameColor']!)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (store.report != null)
                      Text('Orders : ${store.report!.totalOrders ?? 0}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Sora')),
                  ],
                ),
                Text('Sale : ${store.report!.totalSales ?? 0}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Sora', color: _kPurple)),
              ],
            ),
          ),
        ),
        if (_removeMode)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _hideStore(store.storeId),
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _orderCard(AllOrderAdminResponseModel order) {
    DateTime dateTime = DateTime.parse(order.createdAt.toString());
    String time = DateFormat('HH:mm').format(dateTime);
    String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';
    final String source = order.source.toString();

    Color getContainerColor() {
      switch (order.approvalStatus) {
        case 2:
          return const Color(0xffF3EEFF);
        case 3:
          return const Color(0xffFFEFEF);
        default:
          return Colors.white;
      }
    }

    Widget badge(String label, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sora', fontSize: 13)),
        );

    return GestureDetector(
      onTap: () {
        Get.to(() => SuperAdminOrderDetail(order));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: getContainerColor(),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: (order.approvalStatus == 2)
                ? const Color(0xffD9CCFB)
                : (order.approvalStatus == 3)
                    ? const Color(0xffFFD0D0)
                    : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _kBrandGradient),
                  child: SvgPicture.asset(
                    order.orderType == 1 ? 'assets/images/ic_delivery.svg' : 'assets/images/ic_pickup.svg',
                    height: 14,
                    width: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.storeName.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Sora')),
                ),
                if (source == "Mobile User App")
                  badge("Magskr", _kIndigo)
                else if (source == "online")
                  badge("Website", const Color(0xFFFFC107)),
                const SizedBox(width: 6),
                const Icon(Icons.access_time, size: 15),
                Text(time, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Sora', fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${order.shippingAddress?.customerName ?? guestName} / ${order.shippingAddress?.phone ?? guestPhone}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Sora', fontSize: 13),
                  ),
                ),
                Text(
                  '${order.orderNumber != null ? 'order_number'.tr : 'Order ID'} : ${order.orderNumber ?? order.id ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Sora'),
                ),
              ],
            ),
            if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${'delivery_time'.tr}: ${DateFormat('dd-MM-yyyy  HH:mm').format(DateTime.parse(order.deliveryTime!))}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Sora', color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(
                    '${'currency'.tr} ${formatAmount(order.payment?.amount ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Sora', fontSize: 16),
                  ),
                  if ((order.payment?.paymentMethod ?? '').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    paymentIcon(order.payment!.paymentMethod!),
                  ],
                ]),
                if (_isVorbestellen(order.deliveryTime))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Vorbestellen',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Sora', fontSize: 11)),
                  ),
                Row(
                  children: [
                    Text(getApprovalStatusText(order.approvalStatus),
                        style: const TextStyle(fontWeight: FontWeight.w400, fontFamily: 'Sora', fontSize: 13)),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: getStatusColor(order.approvalStatus ?? 0),
                      child: Icon(getStatusIcon(order.approvalStatus ?? 0), color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _kPageGradient),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 20),
                decoration: const BoxDecoration(gradient: _kHeaderGradient),
                child: const Text('Menu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Sora', color: Colors.white)),
              ),
              ListTile(
                leading: const Icon(Icons.store_outlined, color: _kPurple),
                title: const Text('Store Config', style: TextStyle(fontFamily: 'Sora')),
                onTap: () {
                  Get.back();
                  Get.to(() => const StoreConfig());
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: _kPurple),
                title: const Text('Store Status', style: TextStyle(fontFamily: 'Sora')),
                onTap: () {
                  Get.back();
                  Get.to(() => const StoreStatus());
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Status-bar strip stays so the pinned section never slides under the status bar.
            Container(
              height: MediaQuery.of(context).padding.top,
              decoration: const BoxDecoration(gradient: _kHeaderGradient),
            ),
            // Gradient header: menu, greeting, settings, logout + search
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.bottomCenter,
                heightFactor: _headerVisible ? 1 : 0,
                child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              decoration: BoxDecoration(
                gradient: _kHeaderGradient,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _headerIcon(Icons.menu, () => _scaffoldKey.currentState?.openDrawer()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greeting()} 👋',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.white70)),
                            const SizedBox(height: 2),
                            const Text('Super Admin',
                                style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      _headerIcon(Icons.settings_outlined, () => Get.to(() => Settings())),
                      const SizedBox(width: 8),
                      _headerIcon(Icons.logout, () => showLogoutConfirmation(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search stores, orders, names, phones...',
                        hintStyle: const TextStyle(color: Color(0xffAEAEAE), fontSize: 12, fontFamily: 'Sora', fontWeight: FontWeight.w300),
                        prefixIcon: const Icon(Icons.search, color: _kPurple),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
            // Quick actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  _pill(
                    icon: const Icon(Icons.print_outlined, color: _kPurple, size: 18),
                    label: 'Status',
                    onTap: () => Get.to(() => const DeviceStatusScreen()),
                  ),
                  const SizedBox(width: 8),
                  _pill(
                    icon: Image.asset('assets/images/reservationIcon.png', height: 15, width: 15),
                    label: 'Reservation',
                    onTap: () => Get.to(() => AllStoreReservation()),
                  ),
                  const SizedBox(width: 8),
                  _pill(
                    icon: Image.asset('assets/images/reservationIcon.png', height: 15, width: 15),
                    label: 'Reservation V2',
                    onTap: () => Get.to(() => const AllStoreReservationV2()),
                  ),
                  const SizedBox(width: 8),
                  _pill(
                    filled: true,
                    color: isRefreshing ? Colors.grey : _kPurple,
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 16),
                    label: 'Refresh',
                    onTap: isRefreshing ? null : refreshAllData,
                  ),
                  if (_removeMode) ...[
                    const SizedBox(width: 8),
                    _pill(
                      filled: true,
                      color: Colors.red,
                      icon: const Icon(Icons.visibility, color: Colors.white, size: 16),
                      label: 'Show all stores${_hiddenStoreIds.isEmpty ? '' : ' (${_hiddenStoreIds.length} hidden)'}',
                      onTap: _exitRemoveMode,
                    ),
                  ],
                ],
              ),
            ),
            if (searchController.text.isNotEmpty)
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('Found ${filteredStoreList.length} store(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Sora')),
              ),
            filteredStoreList.isEmpty && searchController.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No stores found',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontFamily: 'Sora', fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : RepaintBoundary(
                    child: SizedBox(
                      height: 135,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        itemCount: filteredStoreList.length,
                        itemBuilder: (context, index) => _storeCard(filteredStoreList[index]),
                      ),
                    ),
                  ),
            if (searchController.text.isNotEmpty)
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text('Found ${filteredOrderList.length} order(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Sora')),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isHistoryMode ? Colors.orange.shade700 : _kPurple.withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, size: 16, color: _isHistoryMode ? Colors.orange.shade700 : _kPurple),
                          const SizedBox(width: 6),
                          Text(
                            _isHistoryMode
                                ? '${DateFormat('dd MMM').format(_startDate)} – ${DateFormat('dd MMM yy').format(_endDate)}'
                                : 'History',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(gradient: _kBrandGradient, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Today',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Sora', fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  _statTile('total_order'.tr, _isLoadingTotals ? '...' : '$_totalOrdersCount', _kPurple),
                  const SizedBox(width: 8),
                  _statTile('total_sales'.tr,
                      _isLoadingTotals ? '...' : '${'currency'.tr} ${formatAmount(_totalSalesAmount)}', const Color(0xffE5486F)),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onOrderScroll,
                child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: refreshAllData,
                color: _kPurple,
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
                    itemCount: filteredOrderList.length + (isLoadingMore ? 1 : 0) + (isLoadingPrevious ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && isLoadingPrevious) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _kPurple)),
                        );
                      }
                      int adjustedIndex = isLoadingPrevious ? index - 1 : index;

                      if (adjustedIndex == filteredOrderList.length && isLoadingMore) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _kPurple)),
                        );
                      }

                      if (filteredOrderList.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(top: 50),
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No orders found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontFamily: 'Sora', fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }

                      return _orderCard(filteredOrderList[adjustedIndex]);
                    },
                  ),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return _kPurple;
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

  // Store cards only ever reflect "today", so ignore them and always pull the
  // full order list for the picked date range. Only accepted orders
  // (approvalStatus == 2) count toward totals — pending/declined don't.
  Future<void> _calculateTotals() async {
    setState(() => _isLoadingTotals = true);
    try {
      // The API rejects large limits (422), so page through with the same
      // limit already proven to work for the order list, accumulating until exhausted.
      List<AllOrderAdminResponseModel> allOrders = [];
      int offset = 0;
      const int batchSize = 20;
      const int maxBatches = 200; // safety cap: 4000 orders/day is plenty
      for (int i = 0; i < maxBatches; i++) {
        List<AllOrderAdminResponseModel> batch = await CallService().getAllAdminOrder(
          limit: batchSize,
          offset: offset,
          startDate: DateFormat('yyyy-MM-dd').format(_startDate),
          endDate: DateFormat('yyyy-MM-dd').format(_endDate),
          includePast: true,
        );
        allOrders.addAll(batch);
        if (batch.length < batchSize) break;
        offset += batchSize;
      }
      _totalsOrders = allOrders;
      _applyTotals();
    } catch (e) {
      print('Error calculating totals: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTotals = false);
    }
  }

  // Totals from the cached full order list, skipping hidden stores.
  void _applyTotals() {
    final accepted = _totalsOrders
        .where((o) => o.approvalStatus == 2 && !_hiddenStoreIds.contains(o.storeId))
        .toList();
    setState(() {
      _totalOrdersCount = accepted.length;
      _totalSalesAmount = accepted.fold(0.0, (sum, o) => sum + (o.payment?.amount ?? 0));
    });
  }

  void _hideStore(int? storeId) {
    if (storeId == null) return;
    _hiddenStoreIds.add(storeId);
    _filterData();
    _applyTotals();
  }

  void _exitRemoveMode() {
    _hiddenStoreIds.clear();
    _removeMode = false;
    _filterData();
    _applyTotals();
  }

  Future<void> getAllStoreReport({bool showLoader = true}) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (showLoader && !(Get.isDialogOpen ?? false)) {
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
      }

      GetAdminReportResponseModel REPORT = await CallService().getAdminReportAllStore();

      reports = REPORT.reports ?? [];
      _filterData();
      print('AdminReport length is ${reports!.length}');

      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
    } catch (e) {
      print('Error getting report : $e');
      setState(() {
        isLoading = false;
      });
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
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

      orderList = order;
      _filterData();
      setState(() {
        if (order.length < limit) {
          hasMoreOrders = false;
        }
        print('order length is ${orderList.length}');
        isLoading = false;
      });
      await _calculateTotals();
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
      await prefs.remove(valueShared_STORE_NAME);
      await prefs.remove(valueShared_STORE_LOGO);
      await prefs.remove(valueShared_STORE_BRAND_FOR);
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
            content: Text('Logged out successfully', style: const TextStyle(fontFamily: 'Sora')),
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
            content: Text('Failed to logout. Please try again.', style: const TextStyle(fontFamily: 'Sora')),
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
                      fontFamily: 'Sora'),
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
                          style: const TextStyle(fontFamily: 'Sora', 
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
                          style: const TextStyle(fontFamily: 'Sora', 
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

class _DateRangePickerDialog extends StatefulWidget {
  const _DateRangePickerDialog();

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _startDate == null
                  ? 'Select Start Date'
                  : _endDate == null
                      ? 'Select End Date'
                      : 'Date Range Selected',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Sora',
              ),
            ),
            const SizedBox(height: 6),
            if (_startDate != null)
              Text(
                _endDate != null
                    ? '${DateFormat('dd MMM yyyy').format(_startDate!)}  →  ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                    : 'Start: ${DateFormat('dd MMM yyyy').format(_startDate!)}',
                style: TextStyle(
                  color: const Color(0xFF7B52F0),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Sora',
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              rangeStartDay: _startDate,
              rangeEndDay: _endDate,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFamily: 'Sora',
                ),
              ),
              calendarStyle: CalendarStyle(
                rangeStartDecoration: const BoxDecoration(
                  color: Color(0xFF7B52F0),
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: Color(0xFF7B52F0),
                  shape: BoxShape.circle,
                ),
                rangeStartTextStyle: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                rangeEndTextStyle: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                withinRangeDecoration: BoxDecoration(
                  color: const Color(0xFFEDE7FF),
                  shape: BoxShape.rectangle,
                ),
                rangeHighlightColor: const Color(0xFFEDE7FF),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFD9CCFB),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_endDate != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'start': _startDate!,
                      'end': _endDate!,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B52F0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Sora',
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}