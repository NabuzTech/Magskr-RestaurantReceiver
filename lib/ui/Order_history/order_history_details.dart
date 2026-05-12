import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/order_history_response_model.dart';
import '../../models/print_order_without_ip.dart';
import '../../utils/printer_helper_english.dart';

class OrderHistoryDetails extends StatefulWidget {
  final orderHistoryResponseModel historyOrder;

  const OrderHistoryDetails({super.key, required this.historyOrder});

  @override
  State<OrderHistoryDetails> createState() => _OrderHistoryDetailsState();
}

class _OrderHistoryDetailsState extends State<OrderHistoryDetails> {
  int? orderType = 0;
  bool isPrint = false;
  bool isAutoAccept = false;
  bool isLoading = false;
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  String? storeName;
  String? storeid;
  Timer? _orderTimer;
  @override
  void initState() {
    super.initState();
    // Initialize any required data here
    _initializeData();
  }
  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }
  void _initializeData() async {
    // Initialize shared preferences and other data
    sharedPreferences = await SharedPreferences.getInstance();
    storeName = sharedPreferences.getString('store_name');
    bearerKey = sharedPreferences.getString('bearer_key');
    setState(() {});
  }

  void printData(orderHistoryResponseModel history) async {
    print("🖨️ DEBUG - printData called");

    if (history.approvalStatus != 2) {
      print("❌ DEBUG - Order not accepted, approval status: ${history.approvalStatus}");
      showSnackbar("Error", "Cannot print pending order. Please accept the order first.");
      return;
    }

    if (storeName == null) {
      print("❌ DEBUG - Store name is null");
      showSnackbar("Error", "Store name not available");
      return;
    }
    await sharedPreferences.reload();
    String? localIP = sharedPreferences.getString('printer_ip_0');
    print("🔍 DEBUG - Local IP from SharedPreferences: $localIP");

    if (localIP == null || localIP.isEmpty || localIP.trim().isEmpty) {
      print("📡 DEBUG - Local IP is null/empty, calling printWithoutLocalIp()");
      await printWithoutLocalIp();
    } else {
      print(
          "🖨️ DEBUG - Local IP available, calling PrinterHelperEnglish.printHistoryFromSavedIp()");
      try {
        PrinterHelperEnglish.printHistoryFromSavedIp(
            context: context,
            order: history,
            store: storeName!,
            auto: false
        );
      } catch (e) {
        print("❌ DEBUG - Print error: $e");
        showSnackbar("Print Error", "Failed to print: $e");
        // Fallback to remote print
        await printWithoutLocalIp();
      }
    }
  }
  void showSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
      ),
    );
  }
  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String date = DateFormat('dd-MM-yyyy').format(dateTime);
      String time = DateFormat('HH:mm').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return dateTimeString;
    }
  }
  @override
  Widget build(BuildContext context) {
    // Use widget.historyOrder instead of historyOrder
    final historyOrder = widget.historyOrder;

    final subtotal = historyOrder.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      // Item total (unit price + toppings) * quantity
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      return sum + itemTotal;
    }) ?? 0;

    final discountData = historyOrder.invoice?.discountAmount ?? 0.0;
    final deliveryFee = historyOrder.invoice?.deliveryFee ?? 0.0;
    final grandTotal = subtotal - discountData + deliveryFee;
    var delFee = (historyOrder.invoice?.deliveryFee ?? 0.0).toStringAsFixed(1);
    var Note = historyOrder.note.toString();
    String guestAddress = historyOrder.guestShippingJson?.line1?.toString() ?? '';
    String guestName = historyOrder.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = historyOrder.guestShippingJson?.phone?.toString() ?? '';
    String guestEmail = historyOrder.guestShippingJson?.email?.toString() ?? '';

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
                    historyOrder.orderType == 1
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
              color: (historyOrder.approvalStatus == 2) ? Colors.blue : Colors.grey,
            ),
            onPressed: (historyOrder.approvalStatus == 2)
                ? () {
              printData(historyOrder);
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
                        '${'order_number'.tr} # ${historyOrder.orderNumber ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'invoice_number'.tr}: ${historyOrder.invoice?.invoiceNumber ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'date'.tr}: ${formatDateTime(historyOrder.createdAt ?? '')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (historyOrder.deliveryTime != null && historyOrder.deliveryTime!.isNotEmpty)
                      Center(
                        child: Text(
                          '${'delivery_time'.tr}: ${formatDateTime(historyOrder.deliveryTime ?? '')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: ${(historyOrder.shippingAddress?.customerName != null && historyOrder.shippingAddress!.customerName!.isNotEmpty)
                          ? historyOrder.shippingAddress!.customerName!
                          : guestName}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    if (historyOrder.orderType == 1)
                      Builder(
                        builder: (context) {
                          String displayAddress = '';
                          if (historyOrder.shippingAddress?.line1 != null && historyOrder.shippingAddress!.line1!.isNotEmpty) {
                            displayAddress = '${'address'.tr}: ${historyOrder.shippingAddress!.line1!}, ${historyOrder.shippingAddress?.city ?? ""}';
                          } else {
                            displayAddress = '${'address'.tr}: $guestAddress';
                          }

                          return Text(
                            displayAddress,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          );
                        },
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${(historyOrder.shippingAddress?.phone != null && historyOrder.shippingAddress!.phone!.isNotEmpty)
                          ? historyOrder.shippingAddress!.phone!
                          : guestPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      '${'email'.tr}: ${(historyOrder.user?.username != null && historyOrder.user!.username!.isNotEmpty)
                          ? historyOrder.user?.username
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
                      itemCount: historyOrder.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = historyOrder.items?[index];
                        if (item == null) return const SizedBox.shrink();

                        final toppingsTotal = item.toppings?.fold<double>(
                          0,
                              (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
                        ) ?? 0;
                        final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

                        return _orderItem(
                          item.productName ?? "Unknown",
                          itemTotal.toString(),
                          item,
                          note: item.note ?? "",
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    Note.trim().isNotEmpty
                        ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Note:  ',
                          style: TextStyle(
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
                      visible: isPrint,
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
                                Text(formatAmount(discountData),
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
                      "${'invoice_number'.tr}: ${historyOrder.invoice?.invoiceNumber ?? ''}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "${'payment_method'.tr}: ${historyOrder.payment?.paymentMethod ?? ''}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${'paid'.tr}: ${formatDateTime(historyOrder.createdAt ?? '')}",
                      style:
                      const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    if (historyOrder.bruttoNettoSummary?.isNotEmpty ?? false)
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
                              itemCount: historyOrder.bruttoNettoSummary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = historyOrder.bruttoNettoSummary?[index];
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
              child: _buildActionButtons(
                  context, historyOrder.approvalStatus ?? 0),
            ),
            const SizedBox(height: 30,)
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

  Widget _buildActionButtons(BuildContext context, int approvalStatus) {
    if (orderType == 0) {
      if (approvalStatus == 1) {
        setState(() {
          isPrint = false;
        });
        return Column(
          children: [
            Center(
              child: Text("status_pending".tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w400, color: Colors.orangeAccent)),
            ),
            const SizedBox(
              height: 5,
            ),
          ],
        );
      } else if (approvalStatus == 2) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_accepted".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green[400])),
            ),
            const SizedBox(height: 10),
          ],
        );
      } else if (approvalStatus == 3) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_decline".tr,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red[400]!)),
            ),
            const SizedBox(height: 3),
          ],
        );
      }
    } else {
      if (orderType == 1) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_accepted".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 3),
          ],
        );
      } else if (orderType == 2) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_decline".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 3),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _orderItem(String title, String price, Items item, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity ?? 0}X $title'
                      '${((item.toppings?.isNotEmpty ?? false) && item.variant == null) ? ' [${formatAmount(item.unitPrice)}]' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              Text(
                '${'currency'.tr} ${formatAmount(double.parse(price))}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),

          // Variant info
          if (item.variant != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text("${item.quantity} × ${item.variant!.name ?? ''} [${formatAmount(item.variant!.price ?? 0)} ${'currency'.tr}]",
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13)
              ),
            ),

          // Toppings info
          if ((item.toppings?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.toppings!.map((topping) {
                  final totalPrice = (topping.price ?? 0) * (topping.quantity ?? 0);
                  return Text("${topping.quantity} × ${topping.name} [${formatAmount(totalPrice)}]",
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                }).toList(),

              ),
            ),
          item.note!.isNotEmpty ?
          Row(mainAxisAlignment: MainAxisAlignment.start,
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
                width: MediaQuery.of(context).size.width*0.75,
                child: Text(
                  '${item.note}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          )
              : const SizedBox.shrink(),
        ],
      ),
    );
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
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(netto) ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0),
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printWithoutLocalIp() async {
    print("📡 DEBUG - printWithoutLocalIp called");

    setState(() {
      isLoading = true;
    });

    String? dynamicStoreId = sharedPreferences.getString(valueShared_STORE_KEY);

    print("🔍 DEBUG - Store ID from SharedPreferences: $dynamicStoreId");
    print("🔍 DEBUG - Current storeid variable: $storeid");
    String finalStoreId = dynamicStoreId ?? storeid ?? '';

    print("✅ DEBUG - Final store ID being sent: $finalStoreId");

    var map = {
      "order_id":widget.historyOrder.id ?? '',
      "store_id": finalStoreId
    };

    print("📋 DEBUG - Print Without local Ip map: $map");

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
      _orderTimer = Timer(const Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("order Timeout", "get Details request timed out. Please try again.");
        }
      });
      printOrderWithoutIp model = await CallService().printWithoutIp(map);
      _orderTimer?.cancel();
      setState(() {
        isLoading = false;
      });
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('print'.tr),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("✅ DEBUG - Print without IP successful");

    } catch (e) {
      _orderTimer?.cancel();
      setState(() {
        isLoading = false;
      });

      Get.back();

      print('❌ DEBUG - Print without IP error: $e');

      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('sending'.tr),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

}