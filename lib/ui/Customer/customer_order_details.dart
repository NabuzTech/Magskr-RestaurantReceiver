import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/get_customer_order_details_response_model.dart';

class CustomerOrderDetails extends StatefulWidget {
  final String orderId;
  const CustomerOrderDetails(this.orderId, {super.key});

  @override
  State<CustomerOrderDetails> createState() => _CustomerOrderDetailsState();
}

class _CustomerOrderDetailsState extends State<CustomerOrderDetails> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  GetCustomerOrderDetails? orderDetails;
  bool isLoading = true;
  String? storeName;
  int? orderType = 0;
  @override
  void initState() {
    super.initState();
    initVar();
  }

  Future<void> initVar() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

    if (bearerKey != null) {
      await getStoredta(bearerKey!);
    }

    await getCustomerOrderDetails();
  }

  Future<void> getCustomerOrderDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.dialog(
          Center(
            // child: Lottie.asset(
            //   'assets/animations/burger.json',
            //   width: 150,
            //   height: 150,
            //   repeat: true,
            // ),
          ),
          barrierDismissible: false,
        );
      });

      GetCustomerOrderDetails model = await CallService().getCustomerOrderDetails(widget.orderId);

      setState(() {
        orderDetails = model;
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    } catch (e) {
      print('Error getting Customer Details: $e');
      setState(() {
        isLoading = false;
      });

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'Failed to load order details',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);

      if (storeID == null) {
        print("❌ DEBUG - Store ID is null, cannot fetch store data");
        return null;
      }

      final result = await ApiRepo().getStoreData(bearerKey, storeID);
      String fetchedStoreName = result.name?.toString() ?? "Unknown Store";

      if (mounted) {
        setState(() {
          storeName = fetchedStoreName;
        });
      }

      return fetchedStoreName;
    } catch (e) {
      print("❌ ERROR in getStoredta: $e");
      return null;
    }
  }

  Future<String?> getStoreNameFallback() async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      if (storeID == null || bearerKey == null) return null;

      final store = await ApiRepo().getStoreData(bearerKey!, storeID);
      return store.name?.toString();
    } catch (e) {
      print("❌ Fallback store name error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || orderDetails == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'order_details'.tr,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        body: Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
      );
    }
    var Note=orderDetails!.note.toString();
    var couponCode= orderDetails!.couponCode.toString();
    String guestAddress=orderDetails!.guestShippingJson?.line1?.toString()??'';
    String guestName=orderDetails!.guestShippingJson?.customerName?.toString()??'';
    String guestPhone=orderDetails!.guestShippingJson?.phone?.toString()??'';
    String guestEmail=orderDetails!.guestShippingJson?.email?.toString()??'';
    var delFee = (orderDetails!.invoice?.deliveryFee ?? 0.0).toStringAsFixed(1);
    final subtotal = orderDetails!.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(0, (tSum, topping) =>
      tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),) ?? 0;

      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
      return sum + itemTotal;
    }) ?? 0;

    final discountData = orderDetails!.invoice?.discountAmount ?? 0.0;
    final deliveryFee = orderDetails!.invoice?.deliveryFee ?? 0.0;
    final grandTotal = orderDetails!.invoice?.totalAmount ?? (subtotal - discountData + deliveryFee);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'order_details'.tr,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(
              height: 30,
              width: 25,
              child: IconButton(
                icon: Icon(
                    orderDetails!.orderType == 1
                        ? Icons.car_crash_outlined
                        : Icons.receipt,
                    color: Colors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  // Add your icon's functionality here
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.print,
              color: (orderDetails!.approvalStatus == 2) ? Colors.blue : Colors.grey,
            ),
            onPressed: (orderDetails!.approvalStatus == 2)
                ? () {
            }
                : null,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        '${'order_number'.tr} # ${orderDetails!.orderNumber ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text('${'invoice_number'.tr}: ${orderDetails!.invoice?.invoiceNumber ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'date'.tr}: ${_formatDate(orderDetails!.createdAt)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (orderDetails!.deliveryTime != null && orderDetails!.deliveryTime!.isNotEmpty)
                      Center(
                        child: Text(
                          '${'delivery_time'.tr}: ${_formatDate(orderDetails!.deliveryTime)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: '
                          '${(orderDetails!.shippingAddress?.customerName != null && orderDetails!.shippingAddress!.customerName!.isNotEmpty)
                          ? orderDetails!.shippingAddress!.customerName!
                          : guestName}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    if (orderDetails!.orderType == 1)
                      Text(
                        '${'address'.tr}: ${(orderDetails!.shippingAddress?.line1 != null && orderDetails!.shippingAddress!.line1!.isNotEmpty)
                            ? "${orderDetails!.shippingAddress!.line1!}, ${orderDetails!.shippingAddress?.city ?? ""}"
                            : guestAddress}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${(orderDetails!.shippingAddress?.phone != null && orderDetails!.shippingAddress!.phone!.isNotEmpty)
                          ? orderDetails!.shippingAddress!.phone!
                          : guestPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      '${'email'.tr}: ${(orderDetails!.user?.username != null && orderDetails!.user!.username!.isNotEmpty)
                          ? orderDetails!.user!.username!
                          : guestEmail}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(1),
                      itemCount: orderDetails!.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = orderDetails!.items?[index];
                        if (item == null) return const SizedBox.shrink();
                        final toppingsTotal = item.toppings?.fold<double>(
                          0,
                              (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
                        ) ?? 0;

                        final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

                        return _orderItem(
                          item.productName ?? "Product",
                          itemTotal.toStringAsFixed(2),
                          couponCode,
                          item,
                          note: item.note ?? "",
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    Note.trim().isNotEmpty ?
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'note'.tr}:  ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Text(
                            Note,
                            style: const TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                        : const SizedBox.shrink(),

                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    Visibility(
                      //visible: isPrint,
                      child: Column(
                        children: [
                          const SizedBox(height: 2),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'subtotal'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  formatAmount(subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),]
                          ),
                          const SizedBox(height: 2),
                          Visibility(
                            visible: discountData == 0.0 ? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'discount'.tr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text('-${formatAmount(discountData)}',
                                  // discountData.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Visibility(
                            visible: delFee == "0.0" ? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'delivery_fee'.tr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(formatAmount(deliveryFee),
                                  //delFee.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(height: 0.5, color: Colors.grey),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'grand_total'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),

                              Text(
                                "${'currency'.tr} ${formatAmount((grandTotal))}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),
                          Container(height: 0.5, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${'invoice_number'.tr}: ${orderDetails!.invoice?.invoiceNumber ?? ''}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "${'payment_method'.tr}: ${orderDetails!.payment?.paymentMethod ?? ''}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${'paid'.tr}: ${_formatDate(orderDetails!.createdAt ?? '')}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text('Coupon Applied : $couponCode',style: const TextStyle(
                        fontFamily: 'Mulish',fontSize: 15,fontWeight: FontWeight.w600
                    ),),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    if (orderDetails!.bruttoNettoSummary?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'vat_rate'.tr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'gross'.tr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'net'.tr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'vat'.tr,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: orderDetails!.bruttoNettoSummary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = orderDetails!.bruttoNettoSummary?[index];
                                if (tax == null) return const SizedBox.shrink();
                                return brutoItems(
                                  '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                                  tax.brutto?.toString() ?? "0",
                                  tax.netto?.toString() ?? "0",
                                  tax.taxAmount?.toString() ?? "0",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: _buildStatusDisplay(context, orderDetails!.approvalStatus ?? 0),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
  String formatAmount(double? amount) {
    if (amount == null) return "0";

    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.00#', localeToUse).format(amount);
  }

  Color getStatusColor(int? status) {
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

  Widget _buildStatusDisplay(BuildContext context, int approvalStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: getStatusColor(approvalStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getStatusColor(approvalStatus)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            approvalStatus == 1
                ? Icons.pending
                : approvalStatus == 2
                ? Icons.check_circle
                : Icons.cancel,
            color: getStatusColor(approvalStatus),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            getApprovalStatusText(approvalStatus),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: getStatusColor(approvalStatus),
            ),
          ),
        ],
      ),
    );
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return "status_pending".tr;
      case 2:
        return "status_accepted".tr;
      case 3:
        return "status_decline".tr;
      default:
        return "Unknown";
    }
  }

  Widget brutoItems(String percentage, String brutto, String netto, String? taxAmount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                percentage,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(brutto) ?? 0),
                //netto,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text( formatAmount(double.tryParse(netto) ?? 0),
                // brutto,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0),
                // taxAmount ?? "0",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderItem(String title, String price,String coupon,Items item, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title and price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity ?? 0}X $title'
                          '${((item.toppings?.isNotEmpty ?? false) && item.variant == null) ? ' [${(item.unitPrice)}]' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              Text(
                '${'currency'.tr} ${formatAmount(double.parse(price))}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),

          // Variant info (only if variant exists)
          if (item.variant != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text(
                  "${item.quantity} × ${item.variant!.name ?? ''} [${(item.variant!.price)} ${'currency'.tr}]",
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)
              ),
            ),

          // Toppings info (only if toppings exist and not empty)
          if (item.toppings != null && item.toppings!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.toppings!.map((topping) {
                  final totalPrice = (topping.price ?? 0) * (topping.quantity ?? 0);
                  return Text(
                    "${topping.quantity} × ${topping.name} [${(totalPrice)}]",
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                }).toList(),
              ),
            ),

          if (item.note != null && item.note!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'note'.tr} :',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Text(
                    item.note!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }
}