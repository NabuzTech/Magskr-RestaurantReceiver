import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/all_admin_order_response_model.dart';

class SuperAdminOrderDetail extends StatefulWidget {
  final AllOrderAdminResponseModel order;

  const SuperAdminOrderDetail(this.order, {super.key});

  @override
  _SuperAdminOrderDetailState createState() => _SuperAdminOrderDetailState();
}

class _SuperAdminOrderDetailState extends State<SuperAdminOrderDetail> {
  late SharedPreferences sharedPreferences;
  late AllOrderAdminResponseModel updatedOrder;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initVar();
  }

  Future<void> initVar() async {
    updatedOrder = widget.order;
    sharedPreferences = await SharedPreferences.getInstance();
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

  @override
  Widget build(BuildContext context) {
    var amount = updatedOrder.payment?.amount ?? 0.0;
    var discountData = updatedOrder.invoice?.discountAmount ?? 0.0;
    var deliveryFee = updatedOrder.invoice?.deliveryFee ?? 0.0;

    // Calculate subtotal from all items
    // Calculate subtotal from all items
    final subtotal = updatedOrder.items?.fold<double>(0, (sum, item) {
      // ✅ FIX: Convert topping price from int to double
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) {
          final toppingPrice = (topping.price ?? 0).toDouble();
          final toppingQty = (topping.quantity ?? 0).toDouble();
          return tSum + (toppingPrice * toppingQty);
        },
      ) ?? 0.0;

      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
      return sum + itemTotal;
    }) ?? 0.0;

    final grandTotal = subtotal - discountData + deliveryFee;

    var note = updatedOrder.note?.toString() ?? '';
    String guestAddress = updatedOrder.guestShippingJson?.line1?.toString() ?? '';
    String guestName = updatedOrder.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = updatedOrder.guestShippingJson?.phone?.toString() ?? '';
    String guestEmail = updatedOrder.guestShippingJson?.email?.toString() ?? '';

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
                        ? Icons.delivery_dining
                        : Icons.receipt,
                    color: Colors.blue),
                onPressed: () {
                  // Icon functionality
                },
              ),
            ),
          ],
        ),
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
                    Container(height: 1, color: Colors.grey),
                    const SizedBox(height: 5),

                    // Store Name
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          updatedOrder.storeName ?? 'Unknown Store',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Order Number
                    Center(
                      child: Text(
                        '${'order_number'.tr} # ${updatedOrder.orderNumber ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Invoice Number
                    Center(
                      child: Text(
                        '${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Date
                    Center(
                      child: Text(
                        '${'date'.tr}: ${formatDateTime(updatedOrder.createdAt)}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Delivery Time
                    if (updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty)
                      Center(
                        child: Text(
                          '${'delivery_time'.tr}: ${formatDateTime(updatedOrder.deliveryTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Customer Name
                    Text(
                      '${'customer'.tr}: ${updatedOrder.shippingAddress?.customerName ?? guestName}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    // Address (only for delivery)
                    if (updatedOrder.orderType == 1)
                      Text(
                        '${'address'.tr}: ${updatedOrder.shippingAddress?.line1 ?? guestAddress}${updatedOrder.shippingAddress?.city != null ? ', ${updatedOrder.shippingAddress?.city}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    const SizedBox(height: 2),

                    // Phone
                    Text(
                      '${'phone'.tr}: ${updatedOrder.shippingAddress?.phone ?? guestPhone}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),

                    // Email
                    Text(
                      '${'email'.tr}: ${updatedOrder.user?.username ?? guestEmail}',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(1),
                      itemCount: updatedOrder.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = updatedOrder.items?[index];
                        if (item == null) return const SizedBox.shrink();

                        // ✅ FIX: Calculate toppings total correctly
                        final toppingsTotal = item.toppings?.fold<double>(
                          0,
                              (sum, topping) {
                            // ✅ Convert int to double for calculation
                            final toppingPrice = (topping.price ?? 0).toDouble();
                            final toppingQty = (topping.quantity ?? 0).toDouble();
                            return sum + (toppingPrice * toppingQty);
                          },
                        ) ?? 0.0;

                        final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

                        return _orderItem(
                          item.productName ?? "Product",
                          itemTotal.toStringAsFixed(2),
                          item,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),

                    // Order Note
                    if (note.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
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
                            Expanded(
                              child: Text(
                                note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('subtotal'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        Text(formatAmount(subtotal), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Discount
                    if (discountData > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('discount'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(formatAmount(discountData), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    const SizedBox(height: 2),

                    // Delivery Fee
                    if (deliveryFee > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('delivery_fee'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(formatAmount(deliveryFee), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('grand_total'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                        Text("${'currency'.tr} ${formatAmount(grandTotal)}", style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Payment Method
                    Text(
                      "${'payment_method'.tr}: ${updatedOrder.payment?.paymentMethod ?? 'N/A'}",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    if (updatedOrder.couponCode != null && updatedOrder.couponCode!.isNotEmpty)
                      Text(
                        'Coupon Applied : ${updatedOrder.couponCode}',
                        style: const TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 15,
                            fontWeight: FontWeight.w600
                        ),
                      ),
                    Text(
                      "${'paid'.tr}: ${formatDateTime(updatedOrder.createdAt ?? '')}",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 0.5, color: Colors.grey),
                    const SizedBox(height: 8),

                    // VAT Summary
                    if (updatedOrder.bruttoNettoSummary?.isNotEmpty ?? false)
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
                                    child: Text('vat_rate'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text('gross'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text('net'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('vat'.tr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(12),
                              itemCount: updatedOrder.bruttoNettoSummary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = updatedOrder.bruttoNettoSummary?[index];
                                if (tax == null) return const SizedBox.shrink();
                                return _vatItem(
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Status Display
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: _buildStatusDisplay(context, updatedOrder.approvalStatus ?? 0),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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

  Widget _orderItem(String title, String price, item) {
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
                child: Text(
                  '${item.quantity ?? 0}X $title'
                      '${((item.toppings?.isNotEmpty ?? false) && item.variant == null) ? ' [${formatAmount(item.unitPrice ?? 0)}]' : ''}',  // ✅ Check variant object
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

          // ✅ FIXED: Variant info - use variant object
          if (item.variant != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text(
                  "${item.quantity} × ${item.variant!.name ?? ''} [${formatAmount(item.variant!.price ?? 0)} ${'currency'.tr}]",
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)
              ),
            ),

          // Toppings
          if (item.toppings != null && item.toppings!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.toppings!.map<Widget>((topping) {
                  final totalPrice = (topping.price ?? 0) * (topping.quantity ?? 0);
                  return Text(
                    "${topping.quantity} × ${topping.name} [${formatAmount(totalPrice.toDouble())}]",
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                }).toList(),
              ),
            ),

          // Item Note
          if (item.note != null && item.note!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'note'.tr}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
                Expanded(
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

  Widget _vatItem(String percentage, String brutto, String netto, String? taxAmount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(percentage, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(brutto) ?? 0), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(netto) ?? 0), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}