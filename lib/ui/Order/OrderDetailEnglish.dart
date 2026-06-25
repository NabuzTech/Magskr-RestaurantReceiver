import 'dart:async';
import 'package:flutter/material.dart';
import 'package:food_receiver/utils/my_application.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../Database/databse_helper.dart';
import '../../models/OrderItem.dart';
import '../../models/Store.dart';
import '../../models/order_model.dart';
import '../../models/print_order_without_ip.dart';
import '../../utils/log_util.dart';
import '../../utils/printer_helper_english.dart';

class OrderDetailEnglish extends StatefulWidget {
  final Order order;

  const OrderDetailEnglish(this.order, {super.key});

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetailEnglish> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  late Order updatedOrder;
  int? orderType = 0;
  String? storeName;
  String? storeid;
  bool isPrint = false;
  bool isAutoAccept = false;
  bool isLoading = false;
  Timer? _orderTimer;
  final _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    initVar();
  }

  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }

  Future<void> initVar() async {
    updatedOrder = widget.order;
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    print("📦 Order items count: ${updatedOrder.items?.length ?? 0}");
    updatedOrder.items?.forEach((item) {
      print("   - ${item.productName}: ${item.toppings?.length ?? 0} toppings");
      item.toppings?.forEach((t) {
        print("      * ${t.name} (${t.price} × ${t.quantity})");
      });
    });

    if (bearerKey != null) {
      // ✅ CRITICAL: Wait for store name to be loaded before proceeding
      await getStoredta(bearerKey!);
      print("✅ Store name loaded in initVar: $storeName");
    }
  }

  Future<void> getOrders(String bearerKey, bool isAccept) async {
    Map<String, dynamic> jsonData = {
      "order_status": 2,
      "approval_status": isAccept ? 2 : 3,
    };
    if (isAccept && updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty) {
      jsonData["delivery_time"] = updatedOrder.deliveryTime;
    }
    try {
      // Show loading dialog
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
        ),
        barrierDismissible: false,
      );

      _orderTimer = Timer(const Duration(seconds: 7), () {
        if (mounted && (Get.isDialogOpen == true)) {
          Navigator.of(Get.overlayContext!).pop();
        }
      });

      final prefs = await SharedPreferences.getInstance();
      bool autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
      bool isAutoAccept = prefs.getBool('is_auto_accept') ?? false;

      final result = await Future.any([
        ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0),
        Future.delayed(const Duration(seconds: 10)).then((_) => null)
      ]);

      _orderTimer?.cancel();

      if (mounted && (Get.isDialogOpen == true)) {
        try {
          Navigator.of(Get.overlayContext!).pop();
        } catch (e) {
          print("Error closing dialog: $e");
        }
      }

      if (result == null) {
        if (mounted) {
          Get.snackbar(
            'timeout'.tr,
            'request'.tr,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // ✅ CRITICAL FIX: Always fetch fresh order data after accept/decline
      if (isAccept) {
        try {
          print("🔄 Fetching fresh order data after accept...");
          final refreshedOrder = await ApiRepo().getNewOrderData(bearerKey, updatedOrder.id!);

          print("📊 Fresh Order Data:");
          print("   - Discount: ${refreshedOrder.invoice?.discount_amount}");
          print("   - Delivery Fee: ${refreshedOrder.invoice?.delivery_fee}");
          print("   - Total Amount: ${refreshedOrder.invoice?.totalAmount}");
          print("   - Invoice Number: ${refreshedOrder.invoice?.invoiceNumber}");

          if (mounted) {
            setState(() {
              isPrint = true;
              updatedOrder = refreshedOrder;  // ✅ Use refreshed data with all calculations
              app.appController.updateOrder(refreshedOrder);
              orderType = 1;
            });
          }

          // Auto print logic
          if (autoOrderPrint && !isAutoAccept) {
            if (refreshedOrder.invoice != null &&
                (refreshedOrder.invoice?.invoiceNumber ?? '').isNotEmpty) {

              String? finalStoreName = storeName;

              if (finalStoreName == null || finalStoreName.isEmpty) {
                print("⚠️ Store name is null, trying to fetch...");
                finalStoreName = await getStoredta(bearerKey);
              }

              if (finalStoreName == null || finalStoreName.isEmpty) {
                print("⚠️ Still null, trying fallback...");
                finalStoreName = await getStoreNameFallback();
              }

              print("🖨️ Final store name for printing: '$finalStoreName'");

              if (Get.context != null) {
                PrinterHelperEnglish.printTestFromSavedIp(
                    context: Get.context!,
                    order: refreshedOrder,
                    store: finalStoreName ?? "Restaurant",
                    auto: true
                );
              }
            }
          }
        } catch (e) {
          print("❌ Error fetching fresh order data: $e");
          // Fallback to original result if refresh fails
          if (mounted) {
            setState(() {
              isPrint = true;
              updatedOrder = result;
              app.appController.updateOrder(result);
              orderType = 1;
            });
          }
        }
      } else {
        // For decline, use original result
        if (mounted) {
          setState(() {
            isPrint = true;
            updatedOrder = result;
            app.appController.updateOrder(result);
            orderType = 2;
          });
        }
      }

    } catch (e) {
      _orderTimer?.cancel();

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      String errorMessage = e.toString().contains('timeout')
          ? 'Request timed out. Please check your connection and try again.'
          : 'Order Accept API Exception: $e';

      if (mounted && e.toString().contains('timeout')) {
        Get.snackbar(
          '${'timeout'.tr} ${'error'.tr}',
          errorMessage,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }

      Log.loga(title, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      print("🔍 DEBUG - bearerKey: ${bearerKey.substring(0, 10)}...");
      print("🔍 DEBUG - storeID: $storeID");

      if (storeID == null) {
        print("❌ DEBUG - Store ID is null, cannot fetch store data");
        return null;
      }

      print("🌐 DEBUG - Calling ApiRepo().getStoreData...");
      final result = await ApiRepo().getStoreData(bearerKey, storeID);
      print("🔍 DEBUG - API result: ${'Success'}");

      Store store = result;
      print("🔍 DEBUG - Store object: ${store.toString()}");
      print("🔍 DEBUG - Store name from API: ${store.name}");

      String fetchedStoreName = store.name?.toString() ?? "Unknown Store";
      String fetchedStoreid = store.code?.toString() ?? "Unknown id";

      setState(() {
        storeName = fetchedStoreName;
        storeID = fetchedStoreid;
      });

      print("✅ DEBUG - Final storeName set to: '$storeName'");
      return storeName;
        } catch (e) {
      print("❌ DEBUG - Exception in getStoredta: $e");
      print("❌ DEBUG - Exception type: ${e.runtimeType}");
      Log.loga(title, "getStoredta Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      return null;
    }
  }

  Future<String?> getStoreNameFallback() async {
    try {
      // Try to get from previous session
      String? cachedName = sharedPreferences.getString('last_store_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        print("✅ Using cached store name: $cachedName");
        return cachedName;
      }

      // Try to get from user preferences or default
      return "Default Restaurant"; // Replace with your app's default name
    } catch (e) {
      print("❌ Fallback failed: $e");
      return "Restaurant";
    }
  }

  String formatAmount(double? amount) {
    if (amount == null) return "0";

    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.00#', localeToUse).format(amount);
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
  Widget build(BuildContext context) {
    var amount = (updatedOrder.invoice?.totalAmount ?? 0.0).toStringAsFixed(1);
    var discount = (updatedOrder.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
    var delFee = (updatedOrder.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
    final subtotal = updatedOrder.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
      return sum + itemTotal;
    }) ?? 0;

    // ✅ Use invoice data if available, otherwise calculate manually
    final discountData = updatedOrder.invoice?.discount_amount ?? 0.0;
    final deliveryFee = updatedOrder.invoice?.delivery_fee ?? 0.0;
    final grandTotal = updatedOrder.invoice?.totalAmount ?? (subtotal - discountData + deliveryFee);

    print("💰 Calculation Debug:");
    print("   - Subtotal: $subtotal");
    print("   - Discount: $discountData");
    print("   - Delivery Fee: $deliveryFee");
    print("   - Grand Total: $grandTotal");

    var Note=updatedOrder.note.toString();
    var couponCode= updatedOrder.couponCode.toString();
    String guestAddress=updatedOrder.guestShippingJson?.line1?.toString()??'';
    String guestName=updatedOrder.guestShippingJson?.customerName?.toString()??'';
    String guestPhone=updatedOrder.guestShippingJson?.phone?.toString()??'';
    String guestEmail=updatedOrder.guestShippingJson?.email?.toString()??'';
    print('guest name is $guestName');
    print('guest name is $guestAddress');
    print('guest name is $guestPhone');
    print('Note IS $Note');
    bool localOrder = updatedOrder.isLocalOrder==true;
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
                    updatedOrder.orderType == 1
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
              color: (updatedOrder.approvalStatus == 2) ? Colors.blue : Colors.grey,
            ),
            onPressed: (updatedOrder.approvalStatus == 2)
                ? () {

              printData(updatedOrder);
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
                        '${'order_number'.tr} # ${updatedOrder.orderNumber ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        localOrder
                            ? 'POS Order'
                            : '${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'date'.tr}: ${formatDateTime(updatedOrder.createdAt)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty)
                      Center(
                        child: Text(
                          '${(updatedOrder.orderType == 2 ? 'collection' : 'delivery_time').tr}: ${formatDateTime(updatedOrder.deliveryTime)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    if (_isVorbestellen(updatedOrder.deliveryTime))
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: GestureDetector(
                            onTap: () => _showDeliveryTimeDialog(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Vorbestellen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Mulish',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: '
                          '${(updatedOrder.shipping_address?.customer_name != null && updatedOrder.shipping_address!.customer_name!.isNotEmpty)
                          ? updatedOrder.shipping_address!.customer_name!
                          : guestName}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    if (updatedOrder.orderType == 1)
                      Text(
                        '${'address'.tr}: ${(updatedOrder.shipping_address?.line1 != null && updatedOrder.shipping_address!.line1!.isNotEmpty)
                            ? "${updatedOrder.shipping_address!.line1!}, ${updatedOrder.shipping_address?.city ?? ""}"
                            : guestAddress}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${(updatedOrder.shipping_address?.phone != null && updatedOrder.shipping_address!.phone!.isNotEmpty)
                          ? updatedOrder.shipping_address!.phone!
                          : guestPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      '${'email'.tr}: ${(updatedOrder.user?.username != null && updatedOrder.user!.username!.isNotEmpty)
                          ? updatedOrder.user!.username!
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
                      itemCount: updatedOrder.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = updatedOrder.items?[index];
                        if (item == null) return const SizedBox.shrink();

                        // ✅ FIX: Calculate totals with null safety
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
                      "${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? ''}",
                      style:
                          const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "${'payment_method'.tr}: ${updatedOrder.payment?.paymentMethod ?? ''}",
                      style:
                          const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${'paid'.tr}: ${formatDateTime(updatedOrder.createdAt ?? '')}",
                      style:
                          const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text('Coupon Applied : $couponCode',style: const TextStyle(
                        fontFamily: 'Mulish',fontSize: 15,fontWeight: FontWeight.w600
                    ),),
                    const SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 2),
                    if (updatedOrder.brutto_netto_summary?.isNotEmpty ?? false)
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
                              itemCount: updatedOrder.brutto_netto_summary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = updatedOrder.brutto_netto_summary?[index];
                                if (tax == null) return const SizedBox.shrink();
                                return brutoItems(
                                  '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                                  tax.brutto?.toString() ?? "0",
                                  tax.netto?.toString() ?? "0",
                                  tax.tax_amount?.toString() ?? "0",
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
            GestureDetector(
              onLongPress: () {
                if (updatedOrder.isLocalOrder == true) {
                  _showPaymentMethodDialog();
                } else if (updatedOrder.approvalStatus == 2) {
                  _showDeliveryTimeDialog();
                }
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: _buildActionButtons(context, updatedOrder.approvalStatus ?? 0),
                ),
              ),
            ),
            const SizedBox(height: 30,)
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, int approvalStatus) {
    if (orderType == 0) {
      if (approvalStatus == 1) {
        setState(() {
          isPrint = false;
        });

        // Get current delivery time
        DateTime currentDeliveryTime;
        try {
          currentDeliveryTime = updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty
              ? DateTime.parse(updatedOrder.deliveryTime!)
              : DateTime.now().add(const Duration(minutes: 30));
        } catch (e) {
          currentDeliveryTime = DateTime.now().add(const Duration(minutes: 30));
        }

        // Hide Accept/Decline buttons for all online payments (show only for cash)
        String paymentMethod = updatedOrder.payment?.paymentMethod?.toLowerCase() ?? '';
        bool isCashPayment = paymentMethod == 'cash';
        bool localOrder = updatedOrder.isLocalOrder==true;
        return Column(
          children: [
            // Delivery Time Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(updatedOrder.orderType == 2 ? 'collection' : 'delivery_time').tr}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            currentDeliveryTime = currentDeliveryTime.subtract(const Duration(minutes: 15));
                            updatedOrder.deliveryTime = currentDeliveryTime.toIso8601String();
                          });
                          if (localOrder && updatedOrder.id != null) {
                            _dbHelper.updateOrderDeliveryTime(
                              updatedOrder.id!,
                              currentDeliveryTime.toIso8601String(),
                            );
                          }
                        },
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 28),
                      ),
                      Text(
                        DateFormat('HH:mm').format(currentDeliveryTime),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            currentDeliveryTime = currentDeliveryTime.add(const Duration(minutes: 15));
                            updatedOrder.deliveryTime = currentDeliveryTime.toIso8601String();
                          });
                          if (localOrder && updatedOrder.id != null) {
                            _dbHelper.updateOrderDeliveryTime(
                              updatedOrder.id!,
                              currentDeliveryTime.toIso8601String(),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isCashPayment && !localOrder)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(context, Icons.close, "decline".tr, Colors.red),
                  _actionButton(context, Icons.check, "accept".tr, Colors.green),
                ],
              )
          ],
        );
      }

      else if (approvalStatus == 2) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: getStatusColor(approvalStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: getStatusColor(approvalStatus)),
              ),
              child: Text("status_accepted".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green[400])),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _showCancelConfirmation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text('cancel_order'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      }

      else if (approvalStatus == 3) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: getStatusColor(approvalStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: getStatusColor(approvalStatus)),
              ),
              child: Text("status_decline".tr,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red[400]!)),
            ),
            if (updatedOrder.cancelReason != null && updatedOrder.cancelReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('cancel_reason'.tr,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400])),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(': ${updatedOrder.cancelReason}',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[400])),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 3),
          ],
        );
      }

    } else {
      if (orderType == 1) {  // Manual Accept
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),  // ✅ Change: Add container style
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                "status_accepted".tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,  // ✅ Change: Green color
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      }
      else if (orderType == 2) {  // Manual Decline
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),  // ✅ Change: Add container style
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                "status_decline".tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,  // ✅ Change: Red color
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      }
    }
    return const SizedBox.shrink();
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

  Widget _orderItem(String title, String price,String coupon,OrderItem item, {String? note}) {
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
                          '${((item.toppings?.isNotEmpty ?? false) && item.variant == null) ? ' [${formatAmount(item.unitPrice ?? 0)}]' : ''}',
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
                  "${item.quantity} × ${item.variant!.name ?? ''} [${formatAmount(item.variant!.price ?? 0)} ${'currency'.tr}]",
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
                    "${topping.quantity} × ${topping.name} [${formatAmount(totalPrice)}]",
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                }).toList(),
              ),
            ),

          // Note (only if not empty) - ✅ Added null check
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

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: isLoading ? null : () async {
        if (bearerKey == null) return;

        if (label == 'accept'.tr) {
          if (mounted) {
            setState(() {
              isAutoAccept = false;
              isLoading = true;
            });
          }

          sharedPreferences.setBool('is_auto_accept', false);
          await Future.delayed(const Duration(milliseconds: 100));

          await getOrders(bearerKey!, true);

        } else if (label == 'decline'.tr) {
          if (mounted) {
            setState(() {
              isLoading = true;
            });
          }

          await Future.delayed(const Duration(milliseconds: 100));
          await getOrders(bearerKey!, false);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 40,
            width: 125,
            decoration: BoxDecoration(
              color: isLoading ? color.withOpacity(0.6) : color,  // Visual feedback
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void printData(Order order) async {
    print("🖨️ DEBUG - printData called");

    if (order.approvalStatus != 2) {
      print("❌ DEBUG - Order not accepted, approval status: ${order.approvalStatus}");
      showSnackbar("Error", "Cannot print pending order. Please accept the order first.");
      return;
    }

    if (storeName == null) {
      print("❌ DEBUG - Store name is null");
      showSnackbar("Error", "Store name not available");
      return;
    }

    String? localIP = sharedPreferences.getString('printer_ip_0');
    print("🔍 DEBUG - Local IP from SharedPreferences: $localIP");

    if (localIP == null || localIP.isEmpty) {
      print("📡 DEBUG - Local IP is null/empty, calling printWithoutLocalIp()");
      await printWithoutLocalIp();
    } else {
      print("🖨️ DEBUG - Local IP available, calling PrinterHelperEnglish.printTestFromSavedIp()");
      PrinterHelperEnglish.printTestFromSavedIp(
          context: context,
          order: order,
          store: storeName!,
          auto: false);
    }
  }

  void showSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
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
      "order_id": updatedOrder.id ?? '',
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

      printOrderWithoutIp model = await CallService().printWithoutIp(map);

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

  // ── Cancel Order ────────────────────────────────────────────────

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('cancel_order'.tr),
        content: Text('cancel_order_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no_'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showCancelReasonDialog();
            },
            child: Text('yes'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelReasonDialog() {
    final reasonController = TextEditingController();
    int wordCount = 0;

    bool enoughWords(String text) =>
        text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 5;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('cancel_reason'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'cancel_reason_hint'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setDialogState(() => wordCount =
                      v.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length),
                ),
                if (wordCount > 0 && wordCount < 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('min_5_words'.tr,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enoughWords(reasonController.text)
                      ? Colors.red
                      : Colors.grey[400],
                ),
                onPressed: enoughWords(reasonController.text)
                    ? () {
                        Navigator.pop(context);
                        _cancelOrder(reasonController.text.trim());
                      }
                    : null,
                child: Text('continue'.tr,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancelOrder(String reason) async {
    if (bearerKey == null) return;
    final Map<String, dynamic> jsonData = {
      "order_status": 2,
      "approval_status": 3,
      "cancel_reason": reason,
    };
    try {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Lottie.asset('assets/animations/burger.json',
                width: 150, height: 150, repeat: true),
          ),
        ),
        barrierDismissible: false,
      );
      final result = await Future.any([
        ApiRepo().orderAcceptDecline(bearerKey!, jsonData, updatedOrder.id ?? 0),
        Future.delayed(const Duration(seconds: 10)).then((_) => null),
      ]);
      if (mounted && (Get.isDialogOpen == true)) {
        try { Navigator.of(Get.overlayContext!).pop(); } catch (_) {}
      }
      if (result == null) {
        if (mounted) {
          Get.snackbar('timeout'.tr, 'request'.tr,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      // Fetch fresh order so cancel_reason is included in response
      try {
        final refreshed = await ApiRepo().getNewOrderData(bearerKey!, updatedOrder.id!);
        if (mounted) {
          setState(() {
            updatedOrder = refreshed;
            app.appController.updateOrder(refreshed);
            orderType = 0;
            isPrint = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            updatedOrder = result;
            if (updatedOrder.cancelReason == null || updatedOrder.cancelReason!.isEmpty) {
              updatedOrder.cancelReason = reason;
            }
            app.appController.updateOrder(updatedOrder);
            orderType = 0;
            isPrint = true;
          });
        }
      }
    } catch (e) {
      if (mounted && (Get.isDialogOpen == true)) {
        try { Navigator.of(Get.overlayContext!).pop(); } catch (_) {}
      }
      if (mounted) {
        Get.snackbar('error'.tr, e.toString(),
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _showDeliveryTimeDialog() {
    if (updatedOrder.approvalStatus != 2) return;

    DateTime currentDeliveryTime;
    try {
      currentDeliveryTime = updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty
          ? DateTime.parse(updatedOrder.deliveryTime!)
          : DateTime.now().add(const Duration(minutes: 30));
    } catch (e) {
      currentDeliveryTime = DateTime.now().add(const Duration(minutes: 30));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime updatedTime = currentDeliveryTime;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text((updatedOrder.orderType == 2 ? 'update_collection_time' : 'update_delivery_time').tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(updatedTime),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            updatedTime = updatedTime.subtract(const Duration(minutes: 15));
                          });
                        },
                        icon: const Icon(Icons.remove_circle, size: 40, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () {
                          setDialogState(() {
                            updatedTime = updatedTime.add(const Duration(minutes: 15));
                          });
                        },
                        icon: const Icon(Icons.add_circle, size: 40, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (updatedOrder.isLocalOrder == true && updatedOrder.id != null) {
                      await _dbHelper.updateOrderDeliveryTime(
                        updatedOrder.id!,
                        updatedTime.toIso8601String(),
                      );
                      if (mounted) {
                        setState(() {
                          updatedOrder.deliveryTime = updatedTime.toIso8601String();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delivery time updated',
                                style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      await _updateDeliveryTime(updatedTime);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('saved'.tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPaymentMethodDialog() {
    if (updatedOrder.id == null) return;

    String currentMethod = updatedOrder.payment?.paymentMethod?.toLowerCase() ?? 'cash';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selected = currentMethod;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Payment Method',
                  style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setDialogState(() => selected = 'cash'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: selected == 'cash' ? const Color(0xff0C831F) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected == 'cash' ? const Color(0xff0C831F) : Colors.grey.shade300,
                          width: selected == 'cash' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 22,
                              color: selected == 'cash' ? Colors.white : Colors.black87),
                          const SizedBox(width: 12),
                          Text('Cash',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Mulish',
                                  color: selected == 'cash' ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setDialogState(() => selected = 'card'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected == 'card' ? const Color(0xff0C831F) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected == 'card' ? const Color(0xff0C831F) : Colors.grey.shade300,
                          width: selected == 'card' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.credit_card, size: 22,
                              color: selected == 'card' ? Colors.white : Colors.black87),
                          const SizedBox(width: 12),
                          Text('Card',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Mulish',
                                  color: selected == 'card' ? Colors.white : Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr,
                      style: const TextStyle(fontFamily: 'Mulish', color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _dbHelper.updateOrderPaymentMethod(updatedOrder.id!, selected);
                    if (mounted) {
                      setState(() {
                        updatedOrder.payment?.paymentMethod = selected;
                      });
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Payment method changed to ${selected == 'cash' ? 'Cash' : 'Card'}',
                              style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xff0C831F),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff0C831F)),
                  child: Text('saved'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'Mulish')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateDeliveryTime(DateTime newTime) async {
    if (!mounted) return;

    bool loaderShown = false;
    Timer? timeoutTimer;

    try {
      if (Get.isDialogOpen ?? false) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

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
      loaderShown = true;

      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (loaderShown && (Get.isDialogOpen ?? false)) {
          try {
            Get.back();
            loaderShown = false;
          } catch (e) {
            // Handle error
          }
        }
      });

      Map<String, dynamic> jsonData ={
        "order_status": 2,
        "approval_status": 2,
        "delivery_time": newTime.toIso8601String()
      };
      print('map value is $jsonData');
      final result = await ApiRepo().orderAcceptDecline(
          bearerKey!,
          jsonData,
          updatedOrder.id ?? 0
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('Request timeout', const Duration(seconds: 6));
        },
      );

      timeoutTimer.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        loaderShown = false;
      }

      if (!mounted) return;

      if (result.code == null) {
        setState(() {
          updatedOrder = result;
        });
        app.appController.updateOrder(result);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delivery_time_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.mess ?? 'failed'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on TimeoutException {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request timed out. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      timeoutTimer?.cancel();

      if (loaderShown && (Get.isDialogOpen ?? false)) {
        try {
          Get.back();
        } catch (e) {
          // Handle error
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


}
