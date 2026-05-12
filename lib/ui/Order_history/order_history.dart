import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../../models/order_history_response_model.dart';
import 'order_history_details.dart';

class OrderHistory extends StatefulWidget {
  final List<orderHistoryResponseModel> orders;
  final String targetDate;

  const OrderHistory({
    super.key,
    required this.orders,
    required this.targetDate,
  });

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool _showClearButton = false;
  List<orderHistoryResponseModel> _filteredOrders = [];
  String _searchQuery = '';
  String? _storeType;
  bool isLoading = false;
  IconData getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.pending;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help;
    }
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

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Accepted';
      case 3:
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  Color getContainerColor(int? status) {
    switch (status) {
      case 2: // Accepted
        return const Color(0xffEBFFF4);
      case 3: // Declined
        return const Color(0xffFFEFEF);
      case 1: // Pending
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  String getOrderTypeIcon(int? orderType) {
    switch (orderType) {
      case 1:
        return 'assets/images/ic_delivery.svg';
      case 2:
        return 'assets/images/ic_pickup.svg';
      case 3:
        return 'assets/images/ic_dine_in.svg'; // Assuming you have this
      default:
        return 'assets/images/ic_pickup.svg';
    }
  }

  String getOrderTypeText(int? orderType) {
    switch (orderType) {
      case 1:
        return 'Delivery';
      case 2:
        return 'Pickup';
      case 3:
        return 'Dine In';
      default:
        return 'Unknown';
    }
  }


  String formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  void initState() {
    super.initState();
    _filteredOrders = widget.orders;
    _loadStoreType();

    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text;
    setState(() {
      _searchQuery = query;
      _showClearButton = query.isNotEmpty;
      _filterOrders(query);
    });
  }

  void _filterOrders(String query) {
    if (query.isEmpty) {
      _filteredOrders = widget.orders;
    } else {
      _filteredOrders = widget.orders.where((order) {
        final orderId = order.id?.toString().toLowerCase() ?? '';

        // Get customer name with guest fallback
        final customerName = ((order.shippingAddress?.customerName != null && order.shippingAddress!.customerName!.isNotEmpty)
            ? order.shippingAddress!.customerName!
            : (order.guestShippingJson?.customerName?.toString() ?? order.user?.username ?? '')).toLowerCase();

        // Get phone with guest fallback
        final phone = ((order.shippingAddress?.phone != null && order.shippingAddress!.phone!.isNotEmpty)
            ? order.shippingAddress!.phone!
            : (order.guestShippingJson?.phone?.toString() ?? '')).toLowerCase();

        final searchLower = query.toLowerCase();

        return orderId.contains(searchLower) ||
            customerName.contains(searchLower) ||
            phone.contains(searchLower);
      }).toList();
    }
  }

  String _extractTime(String deliveryTime) {
    try {
      // Parse the ISO string and extract time
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime; // Return original if parsing fails
    }
  }

  Future<void> _loadStoreType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storeType = prefs.getString(valueShared_STORE_TYPE);  // ✅ Use correct constant
      print("📦 Store Type loaded in OrderHistory: $_storeType");  // Debug log
    });
  }

  String _getFullAddress(dynamic shippingAddress, bool isGuest) {
    if (shippingAddress == null) return '';

    List<String> parts = [];

    if (isGuest) {
      // Guest shipping JSON
      if (shippingAddress.line1 != null && shippingAddress.line1.toString().isNotEmpty) {
        parts.add(shippingAddress.line1.toString());
      }
      if (shippingAddress.city != null && shippingAddress.city.toString().isNotEmpty) {
        parts.add(shippingAddress.city.toString());
      }
      // ✅ Check if zip is not "00000" before adding
      if (shippingAddress.zip != null &&
          shippingAddress.zip.toString().isNotEmpty &&
          shippingAddress.zip.toString() != '00000') {
        parts.add(shippingAddress.zip.toString());
      }
      if (shippingAddress.country != null && shippingAddress.country.toString().isNotEmpty) {
        parts.add(shippingAddress.country.toString());
      }
    } else {
      // Regular shipping address
      if (shippingAddress.line1 != null && shippingAddress.line1!.isNotEmpty) {
        parts.add(shippingAddress.line1!);
      }
      if (shippingAddress.city != null && shippingAddress.city!.isNotEmpty) {
        parts.add(shippingAddress.city!);
      }
      // ✅ Check if zip is not "00000" before adding
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'order_history'.tr,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500,fontSize: 20),
        ),
        centerTitle: true,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back()
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.targetDate)),
                style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            padding:  const EdgeInsets.all(8),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color:const Color(0xFFDDE6F3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    autofocus: false,
                    enableInteractiveSelection: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'search_item'.tr,
                      hintStyle: const TextStyle(fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      searchFocusNode.requestFocus();
                    },

                  ),
                ),
                // ✅ Clear search button (simple approach)
                if (_showClearButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        searchController.clear();
                        searchFocusNode.unfocus();
                        setState(() {
                          _searchQuery = '';
                          _showClearButton = false;
                          _filteredOrders = widget.orders; // Reset to original list
                        });
                      },
                      child: const Icon(
                        Icons.clear,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('${"total_order".tr}: ${_filteredOrders.length}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Mulish",
                      color: Colors.black),
                ),
                // SizedBox(width: 10)
              ],
            ),
          ),
          if (_filteredOrders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/empty.json',
                      width: 150,
                      height: 150,
                    ),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No orders found for this date'
                          : 'No orders found for "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = _filteredOrders[index];
                  String time = '';
                  if (order.createdAt != null) {
                    DateTime dateTime = DateTime.parse(order.createdAt!);
                    time = DateFormat('hh:mm a').format(dateTime);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: getContainerColor(order.approvalStatus),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: order.approvalStatus == 2
                            ? const Color(0xffC3F2D9)
                            : order.approvalStatus == 3
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
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                            Get.to(() =>OrderHistoryDetails(historyOrder: order,));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row
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
                                        getOrderTypeIcon(order.orderType),
                                        height: 14,
                                        width: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width*0.6,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width*0.6,
                                            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width * (order.orderType == 2 ? 0.18 : 0.3),
                                                  child: Text(
                                                    order.orderType == 2
                                                        ? 'pickup'.tr
                                                        : (_storeType == '2'
                                                        ? _getFullAddress(
                                                        order.shippingAddress ?? order.guestShippingJson,
                                                        order.shippingAddress == null
                                                    ).trim()
                                                        : (order.shippingAddress?.zip?.toString() ??
                                                        order.guestShippingJson?.zip?.toString() ?? '')),
                                                    maxLines: 2,  // ✅ Allow 2 lines for full address
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 13,
                                                        fontFamily: "Mulish-Regular"
                                                    ),
                                                  ),
                                                ),
                                                if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
                                                  SizedBox(
                                                    width: MediaQuery.of(context).size.width*0.3,
                                                    child: Text(
                                                      '${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                          fontFamily: "Mulish-Regular"
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Visibility(
                                            visible: (_storeType != '2') && (order.shippingAddress != null || order.guestShippingJson != null),
                                            child: SizedBox(
                                              width: MediaQuery.of(context).size.width*0.5,
                                              child: Text(
                                                order.orderType == 1
                                                    ? (order.shippingAddress != null
                                                    ? '${order.shippingAddress!.line1!}, ${order.shippingAddress!.city!}'
                                                    : '${order.guestShippingJson?.line1 ?? ''}, '
                                                    '${order.guestShippingJson?.city ?? ''}')
                                                    : '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
                                                    letterSpacing: 0,
                                                    height: 0,
                                                    fontFamily: "Mulish"
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 4),
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
                                  child: Builder(
                                    builder: (context) {
                                      // Get customer name with guest fallback
                                      String customerName = (order.shippingAddress?.customerName != null && order.shippingAddress!.customerName!.isNotEmpty)
                                          ? order.shippingAddress!.customerName!
                                          : (order.guestShippingJson?.customerName?.toString() ?? order.user?.username ?? "User");

                                      // Get phone with guest fallback
                                      String phone = (order.shippingAddress?.phone != null && order.shippingAddress!.phone!.isNotEmpty)
                                          ? order.shippingAddress!.phone!
                                          : (order.guestShippingJson?.phone?.toString() ?? "N/A");

                                      return Text(
                                        '$customerName / $phone',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: "Mulish",
                                          fontSize: 13,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                     Text(
                                      '${'order_number'.tr} : ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        fontFamily: "Mulish",
                                      ),
                                    ),
                                    Text(
                                      '${order.orderNumber ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        fontFamily: "Mulish",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Amount and status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '€${formatAmount(order.invoice?.totalAmount?.toDouble() ?? 0.0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontFamily: "Mulish",
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      getApprovalStatusText(order.approvalStatus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontFamily: "Mulish-Regular",
                                        fontSize: 13,
                                      ),
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
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}