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
import '../../utils/contact_launcher.dart';
import '../../customView/payment_icon.dart';

import 'package:food_receiver/constants/app_theme.dart';
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
  String? _loadingAction; // label of the button showing the spinner
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

      // ApiRepo returns Order.withError (id == null) instead of throwing.
      if (result.id == null) {
        if (mounted) {
          Get.snackbar('error'.tr, result.mess ?? 'error'.tr,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }

      // ✅ CRITICAL FIX: Always fetch fresh order data after accept/decline
      if (isAccept) {
        try {
          print("🔄 Fetching fresh order data after accept...");
          final refreshedOrder = await ApiRepo().getNewOrderData(bearerKey, updatedOrder.id!);
          if (refreshedOrder.id == null) throw Exception(refreshedOrder.mess); // use PUT result below

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
          _loadingAction = null;
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

  String _fullAddress(String? line1, String? city, String? zip, String? country) {
    return [line1, city, zip, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
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
    String guestAddress=_fullAddress(
      updatedOrder.guestShippingJson?.line1,
      updatedOrder.guestShippingJson?.city,
      updatedOrder.guestShippingJson?.zip,
      updatedOrder.guestShippingJson?.country,
    );
    String guestName=updatedOrder.guestShippingJson?.customerName?.toString()??'';
    String guestPhone=updatedOrder.guestShippingJson?.phone?.toString()??'';
    String guestEmail=updatedOrder.guestShippingJson?.email?.toString()??'';
    String displayAddress = (updatedOrder.shipping_address?.line1 != null && updatedOrder.shipping_address!.line1!.isNotEmpty)
        ? _fullAddress(
            updatedOrder.shipping_address?.line1,
            updatedOrder.shipping_address?.city,
            updatedOrder.shipping_address?.zip,
            updatedOrder.shipping_address?.country,
          )
        : guestAddress;
    String displayPhone = (updatedOrder.shipping_address?.phone != null && updatedOrder.shipping_address!.phone!.isNotEmpty)
        ? updatedOrder.shipping_address!.phone!
        : guestPhone;
    String displayEmail = (updatedOrder.user?.username != null && updatedOrder.user!.username!.isNotEmpty)
        ? updatedOrder.user!.username!
        : guestEmail;
    print('guest name is $guestName');
    print('guest name is $guestAddress');
    print('guest name is $guestPhone');
    print('Note IS $Note');
    bool localOrder = updatedOrder.isLocalOrder==true;
    final customerName = (updatedOrder.shipping_address?.customer_name != null &&
            updatedOrder.shipping_address!.customer_name!.isNotEmpty)
        ? updatedOrder.shipping_address!.customer_name!
        : guestName;
    final approval = updatedOrder.approvalStatus ?? 0;
    final hasNote = Note.trim().isNotEmpty && Note != 'null';
    final hasCoupon = couponCode.trim().isNotEmpty && couponCode != 'null';
    final paymentMethod = updatedOrder.payment?.paymentMethod ?? '';

    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 64,
          leading: Center(
            child: _roundIconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
          ),
          centerTitle: true,
          title: Text(
            'order_details'.tr,
            style: const TextStyle(fontFamily: 'Sora', 
                color: AppTheme.accentDark, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _roundIconButton(
                Icons.print_rounded,
                approval == 2 ? () => printData(updatedOrder) : null,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // ─── Hero: order number, status, times, total ───
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6D5DF6), Color(0xFF4F8DF7)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D5DF6).withOpacity(0.22),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _heroPill(
                        localOrder
                            ? 'POS'
                            : updatedOrder.orderType == 1
                                ? 'delivery'.tr
                                : updatedOrder.orderType == 3
                                    ? 'table'.tr
                                    : 'pickup'.tr,
                        updatedOrder.orderType == 1
                            ? Icons.delivery_dining_rounded
                            : updatedOrder.orderType == 3
                                ? Icons.table_restaurant_rounded
                                : Icons.shopping_bag_rounded,
                      ),
                      const Spacer(),
                      _statusPill(approval),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '#${updatedOrder.orderNumber ?? ''}',
                    style: const TextStyle(fontFamily: 'Sora', 
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        height: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    localOrder
                        ? 'POS Order'
                        : '${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? '-'}',
                    style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _heroTile(Icons.receipt_long_rounded, 'date'.tr,
                            updatedOrder.createdAt),
                      ),
                      if (updatedOrder.deliveryTime != null &&
                          updatedOrder.deliveryTime!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _heroTile(
                            Icons.schedule_rounded,
                            (updatedOrder.orderType == 2 ? 'collection' : 'delivery_time').tr,
                            updatedOrder.deliveryTime,
                            onTap: _isVorbestellen(updatedOrder.deliveryTime)
                                ? _showDeliveryTimeDialog
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isVorbestellen(updatedOrder.deliveryTime))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: _showDeliveryTimeDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB020),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Vorbestellen',
                                  style: TextStyle(fontFamily: 'Sora', 
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white.withOpacity(0.18)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('grand_total'.tr,
                                style: TextStyle(fontFamily: 'Sora', 
                                    color: Colors.white.withOpacity(0.8), fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              "${'currency'.tr} ${formatAmount(grandTotal)}",
                              style: const TextStyle(fontFamily: 'Sora', 
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                      if (paymentMethod.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              paymentIcon(paymentMethod, size: 16),
                              const SizedBox(width: 6),
                              Text(paymentMethod.toLowerCase().tr,
                                  style: const TextStyle(fontFamily: 'Sora', 
                                      color: AppTheme.accentDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Customer ───
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.accentLight,
                        child: Text(
                          customerName.trim().isEmpty
                              ? '?'
                              : customerName.trim()[0].toUpperCase(),
                          style: const TextStyle(fontFamily: 'Sora', 
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('customer'.tr,
                                style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black45)),
                            const SizedBox(height: 2),
                            Text(
                              customerName.isEmpty ? '-' : customerName,
                              style: const TextStyle(fontFamily: 'Sora', 
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppTheme.accentDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (updatedOrder.orderType == 1 && displayAddress.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _navigationIcon(18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(displayAddress,
                              style: const TextStyle(fontFamily: 'Sora', 
                                  fontSize: 13, height: 1.35, color: Colors.black87)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (displayPhone.isNotEmpty)
                        Expanded(
                          child: _contactButton(Icons.call_rounded, 'phone'.tr,
                              () => launchPhone(displayPhone)),
                        ),
                      if (updatedOrder.orderType == 1 && displayAddress.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _contactButton(null, 'address'.tr,
                              () => launchMapAddress(displayAddress),
                              leading: _navigationIcon(20)),
                        ),
                      ],
                      if (displayEmail.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _contactButton(Icons.mail_rounded, 'email'.tr,
                              () => launchEmail(displayEmail)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ─── Order note (kitchen-visible) ───
            if (hasNote)
              Container(
                margin: const EdgeInsets.only(top: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFE2A8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_rounded, size: 20, color: Color(0xFFE09A00)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('note'.tr,
                              style: const TextStyle(fontFamily: 'Sora', 
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF8A5A00))),
                          const SizedBox(height: 4),
                          Text(Note,
                              style: const TextStyle(fontFamily: 'Sora', 
                                  fontSize: 13, height: 1.35, color: Color(0xFF5C3D00))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Items ───
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(Icons.restaurant_menu_rounded, 'order'.tr,
                      trailing: '${updatedOrder.items?.length ?? 0}'),
                  const SizedBox(height: 6),
                  for (int i = 0; i < (updatedOrder.items?.length ?? 0); i++) ...[
                    if (i > 0) const Divider(height: 1, color: Color(0xFFEFEDF8)),
                    Builder(builder: (context) {
                      final item = updatedOrder.items![i];
                      final toppingsTotal = item.toppings?.fold<double>(
                            0,
                            (sum, topping) =>
                                sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
                          ) ??
                          0;
                      final itemTotal =
                          ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
                      return _orderItem(
                        item.productName ?? "Product",
                        itemTotal.toStringAsFixed(2),
                        couponCode,
                        item,
                        note: item.note ?? "",
                      );
                    }),
                  ],
                ],
              ),
            ),

            // ─── Bill ───
            if (isPrint)
              _card(
                child: Column(
                  children: [
                    _amountRow('subtotal'.tr, formatAmount(subtotal)),
                    if (discountData != 0.0)
                      _amountRow('discount'.tr, '-${formatAmount(discountData)}',
                          valueColor: const Color(0xFFDC2626)),
                    if (delFee != "0.0")
                      _amountRow('delivery_fee'.tr, formatAmount(deliveryFee),
                          valueColor: const Color(0xFFEA580C)),
                    if (hasCoupon) _amountRow('Coupon', couponCode),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFEFEDF8)),
                    ),
                    _amountRow('grand_total'.tr,
                        "${'currency'.tr} ${formatAmount(grandTotal)}",
                        bold: true, valueColor: const Color(0xFF16A34A)),
                  ],
                ),
              ),

            // ─── Payment & VAT ───
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle(Icons.account_balance_wallet_rounded, 'payment'.tr),
                  const SizedBox(height: 10),
                  _amountRow('invoice_number'.tr, updatedOrder.invoice?.invoiceNumber ?? '-'),
                  _amountRow('payment_method'.tr, paymentMethod.isEmpty ? '-' : paymentMethod.toLowerCase().tr,
                      valueLeading: paymentMethod.isEmpty ? null : paymentIcon(paymentMethod, size: 18)),
                  _amountRow('paid'.tr, formatDateTime(updatedOrder.createdAt ?? '')),
                  if (updatedOrder.brutto_netto_summary?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F5FD),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text('vat_rate'.tr, style: _tableHead)),
                          Expanded(
                              child: Text('gross'.tr,
                                  style: _tableHead, textAlign: TextAlign.right)),
                          Expanded(
                              child: Text('net'.tr,
                                  style: _tableHead, textAlign: TextAlign.right)),
                          Expanded(
                              child: Text('vat'.tr,
                                  style: _tableHead, textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    for (final tax in updatedOrder.brutto_netto_summary!)
                      brutoItems(
                        '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                        tax.brutto?.toString() ?? "0",
                        tax.netto?.toString() ?? "0",
                        tax.tax_amount?.toString() ?? "0",
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: GestureDetector(
          onLongPress: () {
            if (updatedOrder.isLocalOrder == true) {
              _showPaymentMethodDialog();
            } else if (updatedOrder.approvalStatus == 2) {
              _showDeliveryTimeDialog();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: _buildActionButtons(context, approval),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Order detail layout helpers ───
  static const TextStyle _tableHead =
      TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 11, color: Colors.black54);

  Widget _roundIconButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7E4FA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon,
              size: 20, color: onTap == null ? Colors.black26 : AppTheme.accentDark),
        ),
      ),
    );
  }

  Widget _heroPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(fontFamily: 'Sora', 
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statusPill(int approval) {
    final (String label, Color color, IconData icon) = switch (approval) {
      2 => ('accepted'.tr, const Color(0xFF16A34A), Icons.check_circle_rounded),
      3 => ('decline'.tr, const Color(0xFFDC2626), Icons.cancel_rounded),
      _ => ('pending'.tr, const Color(0xFFF59E0B), Icons.hourglass_top_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontFamily: 'Sora', color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  // Time large, date small underneath, so neither gets truncated.
  Widget _heroTile(IconData icon, String label, String? iso, {VoidCallback? onTap}) {
    final dt = DateTime.tryParse(iso ?? '');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.85), fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(dt == null ? '-' : DateFormat('HH:mm').format(dt),
                style: const TextStyle(fontFamily: 'Sora', 
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, height: 1)),
            const SizedBox(height: 3),
            Text(dt == null ? '' : DateFormat('dd.MM.yyyy').format(dt),
                style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.75), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, String title, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontFamily: 'Sora', 
                fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.accentDark)),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(trailing,
                style: const TextStyle(fontFamily: 'Sora', 
                    color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  // Navigation arrow in a circle, used for the delivery address.
  Widget _navigationIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accent, width: 1.5),
      ),
      child: Icon(Icons.near_me_outlined, size: size * 0.6, color: AppTheme.accent),
    );
  }

  Widget _contactButton(IconData? icon, String label, VoidCallback onTap, {Widget? leading}) {
    return Material(
      color: const Color(0xFFF4F2FE),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              leading ?? Icon(icon, size: 20, color: AppTheme.accent),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Sora', 
                      fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountRow(String label, String value,
      {bool bold = false, Color? valueColor, Widget? valueLeading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Sora', 
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: bold ? 18 : 13,
                  color: valueColor ?? (bold ? AppTheme.accentDark : Colors.black54))),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (valueLeading != null) ...[valueLeading, const SizedBox(width: 6)],
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontFamily: 'Sora', 
                          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                          fontSize: bold ? 22 : 13,
                          color: valueColor ?? (bold ? AppTheme.accent : Colors.black87))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filled status banner used in the bottom bar once the order is decided.
  Widget _statusBanner(String text, Color color, IconData icon) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppTheme.accentLight,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: AppTheme.accent),
        ),
      ),
    );
  }

  // Accepted banner + cancel order button.
  Widget _acceptedRow() {
    return Row(
      children: [
        Expanded(
          child: _statusBanner("accepted".tr, const Color(0xFF16A34A),
              Icons.check_circle_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _showCancelConfirmation,
              icon: const Icon(Icons.block_rounded, size: 18),
              label: Text('cancel_order'.tr,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
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
        // Cash and EC card orders are accepted/declined manually.
        bool isCashPayment = paymentMethod == 'cash' || paymentMethod.startsWith('ec');
        bool localOrder = updatedOrder.isLocalOrder==true;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delivery time stepper
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 20, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (updatedOrder.orderType == 2 ? 'collection' : 'delivery_time').tr,
                    style: const TextStyle(fontFamily: 'Sora', 
                        fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.accentDark),
                  ),
                ),
                _stepButton(Icons.remove_rounded, () {
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
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    DateFormat('HH:mm').format(currentDeliveryTime),
                    style: const TextStyle(fontFamily: 'Sora', 
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accentDark,
                    ),
                  ),
                ),
                _stepButton(Icons.add_rounded, () {
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
                }),
              ],
            ),

            if (isCashPayment && !localOrder) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _actionButton(context, Icons.close_rounded, "decline".tr, Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 2,
                      child: _actionButton(context, Icons.check_rounded, "accept".tr, AppTheme.accent)),
                ],
              ),
            ],
          ],
        );
      }

      else if (approvalStatus == 2) {
        setState(() {
          isPrint = true;
        });
        return _acceptedRow();
      }

      else if (approvalStatus == 3) {
        setState(() {
          isPrint = true;
        });
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusBanner("decline".tr, const Color(0xFFDC2626), Icons.cancel_rounded),
            if (updatedOrder.cancelReason != null && updatedOrder.cancelReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${'cancel_reason'.tr}: ${updatedOrder.cancelReason}',
                  style: const TextStyle(fontFamily: 'Sora', 
                      fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFB91C1C)),
                ),
              ),
            ],
          ],
        );
      }

    } else {
      if (orderType == 1) {  // Manual Accept
        setState(() {
          isPrint = true;
        });
        return _acceptedRow();
      }
      else if (orderType == 2) {  // Manual Decline
        setState(() {
          isPrint = true;
        });
        return _statusBanner("decline".tr, const Color(0xFFDC2626), Icons.cancel_rounded);
      }
    }
    return const SizedBox.shrink();
  }

  Color getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return AppTheme.accent;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _orderItem(String title, String price,String coupon,OrderItem item, {String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.quantity ?? 0}×',
              style: const TextStyle(fontFamily: 'Sora', 
                  fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontFamily: 'Sora', 
                            fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accentDark),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${'currency'.tr} ${formatAmount(double.parse(price))}',
                      style: const TextStyle(fontFamily: 'Sora', 
                          fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accentDark),
                    ),
                  ],
                ),
                if ((item.toppings?.isNotEmpty ?? false) && item.variant == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${'currency'.tr} ${formatAmount(item.unitPrice ?? 0)} / Stk.',
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black45),
                    ),
                  ),

                // Variant
                if (item.variant != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${item.variant!.name ?? ''} · ${formatAmount(item.variant!.price ?? 0)} ${'currency'.tr}",
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black54),
                    ),
                  ),

                // Toppings
                if (item.toppings != null && item.toppings!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.toppings!.map((topping) {
                        final totalPrice = (topping.price ?? 0) * (topping.quantity ?? 0);
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "+ ${topping.quantity}× ${topping.name}",
                                  style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black54),
                                ),
                              ),
                              Text(
                                formatAmount(totalPrice),
                                style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.black45),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Item note
                if (item.note != null && item.note!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFE09A00)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.note!,
                            style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Color(0xFF5C3D00)),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget brutoItems(String percentage, String brutto, String netto, String? taxAmount) {
    const style = TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(percentage, style: style)),
          Expanded(
              child: Text(formatAmount(double.tryParse(brutto) ?? 0),
                  style: style, textAlign: TextAlign.right)),
          Expanded(
              child: Text(formatAmount(double.tryParse(netto) ?? 0),
                  style: style, textAlign: TextAlign.right)),
          Expanded(
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0),
                  style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: isLoading ? null : () async {
        if (bearerKey == null) return;
        setState(() => _loadingAction = label);

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
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          // Accept = theme gradient, decline = soft red outline
          gradient: color == AppTheme.accent
              ? const LinearGradient(colors: [Color(0xFF6D5DF6), Color(0xFF4F8DF7)])
              : null,
          color: color == AppTheme.accent ? null : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: color == AppTheme.accent ? null : Border.all(color: const Color(0xFFFCA5A5)),
          boxShadow: color == AppTheme.accent
              ? [
                  BoxShadow(
                    color: const Color(0xFF6D5DF6).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _loadingAction == label
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: color == AppTheme.accent ? Colors.white : const Color(0xFFDC2626),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 20,
                        color: color == AppTheme.accent ? Colors.white : const Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Sora', 
                          color: color == AppTheme.accent ? Colors.white : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
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
        content: Text('$title: $message', style: const TextStyle(fontFamily: 'Sora')),
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
          content: Text('print'.tr, style: const TextStyle(fontFamily: 'Sora')),
          backgroundColor: AppTheme.accent,
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
          content: Text('sending'.tr, style: const TextStyle(fontFamily: 'Sora')),
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
        title: Text('cancel_order'.tr, style: const TextStyle(fontFamily: 'Sora')),
        content: Text('cancel_order_confirm'.tr, style: const TextStyle(fontFamily: 'Sora')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no_'.tr, style: const TextStyle(fontFamily: 'Sora')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showCancelReasonDialog();
            },
            child: Text('yes'.tr, style: const TextStyle(fontFamily: 'Sora', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCancelReasonDialog() {
    final reasonController = TextEditingController();
    bool enoughWords(String text) => text.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('cancel_reason'.tr, style: const TextStyle(fontFamily: 'Sora')),
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
                  onChanged: (v) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'Sora')),
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
                    style: const TextStyle(fontFamily: 'Sora', color: Colors.white)),
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
      // ApiRepo returns Order.withError (id == null) instead of throwing.
      if (result.id == null) {
        if (mounted) {
          Get.snackbar('error'.tr, result.mess ?? 'error'.tr,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      // Fetch fresh order so cancel_reason is included; fall back to the PUT result.
      final refreshed = await ApiRepo().getNewOrderData(bearerKey!, updatedOrder.id!);
      final cancelled = refreshed.id != null ? refreshed : result;
      cancelled.approvalStatus = 3;
      if (cancelled.cancelReason == null || cancelled.cancelReason!.isEmpty) {
        cancelled.cancelReason = reason;
      }
      app.appController.updateOrder(cancelled);
      if (mounted) {
        setState(() {
          updatedOrder = cancelled;
          orderType = 0;
          isPrint = true;
        });
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
              title: Text((updatedOrder.orderType == 2 ? 'update_collection_time' : 'update_delivery_time').tr, style: const TextStyle(fontFamily: 'Sora')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(updatedTime),
                    style: const TextStyle(fontFamily: 'Sora', 
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
                        icon: const Icon(Icons.add_circle, size: 40, color: AppTheme.accent),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'Sora')),
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
                                style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
                            backgroundColor: AppTheme.accent,

                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      await _updateDeliveryTime(updatedTime);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  child: Text('saved'.tr, style: const TextStyle(fontFamily: 'Sora', color: Colors.white)),
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
                  style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700, fontSize: 16)),
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
                        color: selected == 'cash' ? AppTheme.accent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected == 'cash' ? AppTheme.accent : Colors.grey.shade300,
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
                                  fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Sora',
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
                        color: selected == 'card' ? AppTheme.accent : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected == 'card' ? AppTheme.accent : Colors.grey.shade300,
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
                                  fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Sora',
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
                      style: const TextStyle(fontFamily: 'Sora', color: Colors.grey)),
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
                              style: const TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.accent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  child: Text('saved'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'Sora')),
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
            content: Text('delivery_time_updated'.tr, style: const TextStyle(fontFamily: 'Sora')),
            backgroundColor: AppTheme.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.mess ?? 'failed'.tr, style: const TextStyle(fontFamily: 'Sora')),
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
            content: Text('Request timed out. Please try again.', style: const TextStyle(fontFamily: 'Sora')),
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
            content: Text('Error: ${e.toString()}', style: const TextStyle(fontFamily: 'Sora')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


}
