import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../api/repository/api_repository.dart';
import '../../../customView/payment_icon.dart';
import '../../../constants/constant.dart';
import '../../../models/order_history_response_model.dart';
import '../../../utils/my_application.dart';
import '../../Order_history/order_history_details.dart';

// Same palette as OrderScreenNew.
const _kViolet = Color(0xFFA42BF0);
const _kPurple = Color(0xFF7B52F0);
const _kIndigo = Color(0xFF5B4FE8);
const _kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_kViolet, _kPurple, _kIndigo],
);
const _kPageGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFF6EEFF), Color(0xFFF0EDFF), Color(0xFFEAEBFF)],
);

class AdminOrder extends StatefulWidget {
  const AdminOrder({super.key});

  @override
  State<AdminOrder> createState() => _AdminOrderState();
}

class _AdminOrderState extends State<AdminOrder>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool isLoading = false;
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  String dateSeleted = "";
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;
  String? _storeType;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  List<orderHistoryResponseModel> ordersList = [];
  String? _statusFilter; // null | 'accepted' | 'declined' | 'pickup' | 'delivery'
  String delivery = '0', pickUp = '0', pending = '0', accepted = '0', declined = '0';

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initVar();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> initVar() async {
    setState(() {
      isLoading = true;
    });

    try {
      sharedPreferences = await SharedPreferences.getInstance();
      bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
      _storeType = sharedPreferences.getString(valueShared_STORE_TYPE);

      await orderHistory();
    } catch (e) {
      print('Error in initVar: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> orderHistory() async {
    try {
      final targetDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int storeId = int.tryParse(prefs.getString(valueShared_STORE_KEY) ?? '') ?? 13;

      var map = {
        "store_id": storeId,
        "target_date": targetDate,
        "offset": 0
      };

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      await Future.delayed(const Duration(milliseconds: 150));

      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );

      List<orderHistoryResponseModel> orders = await CallService().orderHistory(map);

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      setState(() {
        ordersList = orders;
        _calculateCounts();
      });

      app.appController.setHistoryOrders(orders);
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'during'.tr}: $e', style: const TextStyle(fontFamily: 'Sora')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _calculateCounts() {
    int deliveryCount = 0;
    int pickupCount = 0;
    int pendingCount = 0;
    int acceptedCount = 0;
    int declinedCount = 0;

    for (var order in ordersList) {
      // Count by order type
      if (order.orderType == 1) {
        deliveryCount++;
      } else if (order.orderType == 2) {
        pickupCount++;
      }

      // Count by approval status
      if (order.approvalStatus == 1) {
        pendingCount++;
      } else if (order.approvalStatus == 2) {
        acceptedCount++;
      } else if (order.approvalStatus == 3) {
        declinedCount++;
      }
    }

    setState(() {
      delivery = deliveryCount.toString();
      pickUp = pickupCount.toString();
      pending = pendingCount.toString();
      accepted = acceptedCount.toString();
      declined = declinedCount.toString();
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds < 1) return;
    }

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    try {
      await  orderHistory();
    } finally {
      _isRefreshing = false;
    }
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

  String formatAmount(double amount) {
    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
  }

  String _extractTime(String deliveryTime) {
    try {
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime;
    }
  }

  String _getFullAddress(dynamic shippingAddress, bool isGuest) {
    if (shippingAddress == null) return '';

    List<String> parts = [];

    if (isGuest) {
      if (shippingAddress.line1 != null && shippingAddress.line1.toString().isNotEmpty) {
        parts.add(shippingAddress.line1.toString());
      }
      if (shippingAddress.city != null && shippingAddress.city.toString().isNotEmpty) {
        parts.add(shippingAddress.city.toString());
      }
      if (shippingAddress.zip != null &&
          shippingAddress.zip.toString().isNotEmpty &&
          shippingAddress.zip.toString() != '00000') {
        parts.add(shippingAddress.zip.toString());
      }
      if (shippingAddress.country != null && shippingAddress.country.toString().isNotEmpty) {
        parts.add(shippingAddress.country.toString());
      }
    } else {
      if (shippingAddress.line1 != null && shippingAddress.line1!.isNotEmpty) {
        parts.add(shippingAddress.line1!);
      }
      if (shippingAddress.city != null && shippingAddress.city!.isNotEmpty) {
        parts.add(shippingAddress.city!);
      }
      if (shippingAddress.zip != null &&
          shippingAddress.zip!.isNotEmpty &&
          shippingAddress.zip != '00000') {
        parts.add(shippingAddress.zip!);
      }
      if (shippingAddress.country != null && shippingAddress.country!.isNotEmpty) {
        parts.add(shippingAddress.country!);
      }
    }

    return parts.join(', ');
  }

  // Tap filters the order list by this status; tap again clears the filter.
  Widget _buildStatusContainer(String text, Color backgroundColor, String filter) {
    final selected = _statusFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = selected ? null : filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPurple : backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? _kPurple : Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: selected ? Colors.white : Colors.black87),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  List<orderHistoryResponseModel> get _filteredOrders {
    switch (_statusFilter) {
      case 'accepted':
        return ordersList.where((o) => o.approvalStatus == 2).toList();
      case 'declined':
        return ordersList.where((o) => o.approvalStatus == 3).toList();
      case 'pickup':
        return ordersList.where((o) => o.orderType == 2).toList();
      case 'delivery':
        return ordersList.where((o) => o.orderType == 1).toList();
      default:
        return ordersList;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final orders = _filteredOrders;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _kPageGradient),
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Builder(builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('order'.tr,
                                style: const TextStyle(fontFamily: 'Sora', 
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              dateSeleted.isEmpty
                                  ? DateFormat('d MMMM, y').format(DateTime.now())
                                  : dateSeleted,
                              style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${'total_order'.tr}: ${ordersList.length}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Sora',
                                color: Colors.black),
                          ),
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.refresh),
                            onPressed: _handleRefresh,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusContainer(
                          '${'accepted'.tr} $accepted',
                          _kPurple.withOpacity(0.12),
                          'accepted',
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"decline".tr} $declined',
                          Colors.red.withOpacity(0.1),
                          'declined',
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"pickup".tr} $pickUp',
                          Colors.blue.withOpacity(0.1),
                          'pickup',
                        ),
                        const SizedBox(width: 8),
                        _buildStatusContainer(
                          '${"delivery".tr} $delivery',
                          Colors.purple.withOpacity(0.1),
                          'delivery',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: false,
                  removeBottom: true,
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: _kPurple,
                    backgroundColor: Colors.white,
                    displacement: 60,
                    child: orders.isEmpty
                        ? ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/empty.json',
                              width: 150,
                              height: 150,
                            ),
                            Text(
                              'no_order'.tr,
                              style: const TextStyle(fontFamily: 'Sora', 
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        DateTime dateTime = DateTime.parse(order.createdAt.toString());
                        String time = DateFormat('hh:mm a').format(dateTime);
                        String guestAddress = order.guestShippingJson?.zip?.toString() ?? '';
                        String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
                        String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';
                        final String source = order.source.toString();

                        return AnimatedBuilder(
                          animation: _opacityAnimation,
                          builder: (context, child) {
                            final bool isPending = (order.approvalStatus ?? 0) == 1;

                            Color getContainerColor() {
                              switch (order.approvalStatus) {
                                case 2:
                                  return const Color(0xffF3EEFF);
                                case 3:
                                  return const Color(0xffFFEFEF);
                                case 1:
                                  return Colors.white;
                                default:
                                  return Colors.white;
                              }
                            }

                            return Opacity(
                              opacity: isPending ? _opacityAnimation.value : 1.0,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: getContainerColor(),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: (order.approvalStatus == 2)
                                        ? const Color(0xffD9CCFB)
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      Get.to(() =>OrderHistoryDetails(historyOrder: order,));
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                    order.orderType == 1
                                                        ? 'assets/images/ic_delivery.svg'
                                                        : order.orderType == 3
                                                        ? 'assets/images/table.svg'
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
                                                      width: MediaQuery.of(context).size.width * 0.43,
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          SizedBox(
                                                            width: MediaQuery.of(context).size.width * (_storeType == '2' ? 0.35 :
                                                            (order.orderType == 2 ? 0.2 : 0.2)),
                                                            child: Text(
                                                              order.orderType == 2
                                                                  ? 'pickup'.tr
                                                                  : (_storeType == '2'
                                                                  ? _getFullAddress(
                                                                  order.shippingAddress ?? order.guestShippingJson,
                                                                  order.shippingAddress == null)
                                                                  : (order.shippingAddress?.zip?.toString() ?? guestAddress)),
                                                              style: const TextStyle(
                                                                  fontWeight: FontWeight.w700,
                                                                  fontSize: 13,
                                                                  fontFamily: 'Sora'),
                                                            ),
                                                          ),
                                                          if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
                                                            SizedBox(
                                                              width: MediaQuery.of(context).size.width * 0.22,
                                                              child: Text(
                                                                '${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
                                                                style: const TextStyle(
                                                                    fontWeight: FontWeight.w700,
                                                                    fontSize: 13,
                                                                    fontFamily: 'Sora'),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible: (_storeType != '2') &&
                                                          (order.shippingAddress != null || order.guestShippingJson != null),
                                                      child: SizedBox(
                                                        width: MediaQuery.of(context).size.width * 0.4,
                                                        child: Text(
                                                          order.orderType == 1
                                                              ? (order.shippingAddress != null
                                                              ? '${order.shippingAddress!.line1!}, ${order.shippingAddress!.city!}'
                                                              : '${order.guestShippingJson?.line1 ?? ''}, ${order.guestShippingJson?.city ?? ''}')
                                                              : '',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w500,
                                                              fontSize: 11,
                                                              letterSpacing: 0,
                                                              height: 0,
                                                              fontFamily: 'Sora'),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                            if (source == "Mobile User App")
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _kIndigo,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "Magskr",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Sora',
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              )
                                            else if (source == "online")
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFC107),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "Website",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Sora',
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              )
                                            else if (source.toLowerCase() == "pos")
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1976D2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "POS",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Sora',
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time, size: 15),
                                                Text(
                                                  time,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Sora',
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
                                            Flexible(
                                              child: SizedBox(
                                                width: MediaQuery.of(context).size.width * 0.5,
                                                child: Text(
                                                  '${order.shippingAddress?.customerName ?? guestName} / ${order.shippingAddress?.phone ?? guestPhone}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontFamily: 'Sora',
                                                      fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${'order_number'.tr} : ',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                      fontFamily: 'Sora'),
                                                ),
                                                Text(
                                                  '${order.orderNumber}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 11,
                                                      fontFamily: 'Sora'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(children: [
                                              Text(
                                                order.payment != null
                                                    ? '${'currency'.tr} ${formatAmount(order.payment!.amount ?? 0)}'
                                                    : '${'currency'.tr} ${formatAmount(0)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'Sora',
                                                    fontSize: 16),
                                              ),
                                              if ((order.payment?.paymentMethod ?? '').isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                paymentIcon(order.payment!.paymentMethod!),
                                              ],
                                            ]),
                                            if (_isVorbestellen(order.deliveryTime))
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Vorbestellen',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Sora',
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            Row(
                                              children: [
                                                Text(
                                                  getApprovalStatusText(order.approvalStatus),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w400,
                                                      fontFamily: 'Sora',
                                                      fontSize: 13),
                                                ),
                                                const SizedBox(width: 6),
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: getStatusColor(order.approvalStatus ?? 0),
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
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}