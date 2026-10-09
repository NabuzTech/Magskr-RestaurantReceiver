import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/all_admin_order_response_model.dart';
import 'package:food_receiver/constants/app_theme.dart';
import 'package:food_receiver/utils/contact_launcher.dart';
import 'package:food_receiver/customView/payment_icon.dart';

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

  String _fullAddress(String? line1, String? city, String? zip, String? country) {
    return [line1, city, zip, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(', ');
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

    final o = updatedOrder;
    final subtotal = o.items?.fold<double>(0, (sum, item) {
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
      return sum + itemTotal;
    }) ?? 0;

    final discountData = o.invoice?.discountAmount ?? 0.0;
    final deliveryFee = o.invoice?.deliveryFee ?? 0.0;
    final grandTotal = o.invoice?.totalAmount ?? (subtotal - discountData + deliveryFee);

    var Note = o.note.toString();
    var couponCode = o.couponCode.toString();
    String guestAddress = _fullAddress(
      o.guestShippingJson?.line1,
      o.guestShippingJson?.city,
      o.guestShippingJson?.zip,
      o.guestShippingJson?.country,
    );
    String guestName = o.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = o.guestShippingJson?.phone?.toString() ?? '';
    String guestEmail = o.guestShippingJson?.email?.toString() ?? '';
    String displayAddress = (o.shippingAddress?.line1 != null && o.shippingAddress!.line1!.isNotEmpty)
        ? _fullAddress(
            o.shippingAddress?.line1,
            o.shippingAddress?.city,
            o.shippingAddress?.zip,
            o.shippingAddress?.country,
          )
        : guestAddress;
    String displayPhone = (o.shippingAddress?.phone != null && o.shippingAddress!.phone!.isNotEmpty)
        ? o.shippingAddress!.phone!
        : guestPhone;
    String displayEmail = (o.user?.username != null && o.user!.username!.isNotEmpty)
        ? o.user!.username!
        : guestEmail;
    final customerName = (o.shippingAddress?.customerName != null &&
            o.shippingAddress!.customerName!.isNotEmpty)
        ? o.shippingAddress!.customerName!
        : guestName;
    final approval = o.approvalStatus ?? 0;
    final hasNote = Note.trim().isNotEmpty && Note != 'null';
    final hasCoupon = couponCode.trim().isNotEmpty && couponCode != 'null';
    final paymentMethod = o.payment?.paymentMethod ?? '';
    final String? cancelReason = updatedOrder.cancelReason;

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
                        o.orderType == 1
                            ? 'delivery'.tr
                            : o.orderType == 3
                                ? 'table'.tr
                                : 'pickup'.tr,
                        o.orderType == 1
                            ? Icons.delivery_dining_rounded
                            : o.orderType == 3
                                ? Icons.table_restaurant_rounded
                                : Icons.shopping_bag_rounded,
                      ),
                      const Spacer(),
                      _statusPill(approval),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '#${o.orderNumber ?? ''}',
                    style: const TextStyle(fontFamily: 'Sora', 
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        height: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${'invoice_number'.tr}: ${o.invoice?.invoiceNumber ?? '-'}',
                    style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    o.storeName ?? 'Unknown Store',
                    style: TextStyle(fontFamily: 'Sora', color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _heroTile(Icons.receipt_long_rounded, 'date'.tr, o.createdAt),
                      ),
                      if (o.deliveryTime != null && o.deliveryTime!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _heroTile(
                            Icons.schedule_rounded,
                            (o.orderType == 2 ? 'collection' : 'delivery_time').tr,
                            o.deliveryTime,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isVorbestellen(o.deliveryTime))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
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
                  if (o.orderType == 1 && displayAddress.isNotEmpty) ...[
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
                      if (o.orderType == 1 && displayAddress.isNotEmpty) ...[
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
                      trailing: '${o.items?.length ?? 0}'),
                  const SizedBox(height: 6),
                  for (int i = 0; i < (o.items?.length ?? 0); i++) ...[
                    if (i > 0) const Divider(height: 1, color: Color(0xFFEFEDF8)),
                    Builder(builder: (context) {
                      final item = o.items![i];
                      final toppingsTotal = item.toppings?.fold<double>(
                            0,
                            (sum, topping) =>
                                sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
                          ) ??
                          0;
                      final itemTotal =
                          ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);
                      return _orderItem(item.productName ?? "Product", itemTotal, item);
                    }),
                  ],
                ],
              ),
            ),

            // ─── Bill ───
            if (approval != 1)
              _card(
                child: Column(
                  children: [
                    _amountRow('subtotal'.tr, formatAmount(subtotal)),
                    if (discountData != 0.0)
                      _amountRow('discount'.tr, '-${formatAmount(discountData)}',
                          valueColor: const Color(0xFFDC2626)),
                    if (deliveryFee != 0.0)
                      _amountRow('delivery_fee'.tr, '+${formatAmount(deliveryFee)}',
                          valueColor: const Color(0xFF16A34A)),
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
                  _amountRow('invoice_number'.tr, o.invoice?.invoiceNumber ?? '-'),
                  _amountRow('payment_method'.tr,
                      paymentMethod.isEmpty ? '-' : paymentMethod.toLowerCase().tr,
                      valueLeading: paymentMethod.isEmpty ? null : paymentIcon(paymentMethod, size: 18)),
                  _amountRow('paid'.tr, formatDateTime(o.createdAt ?? '')),
                  if (o.bruttoNettoSummary?.isNotEmpty ?? false) ...[
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
                    for (final tax in o.bruttoNettoSummary!)
                      _vatRow(
                        '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                        tax.brutto ?? 0,
                        tax.netto ?? 0,
                        tax.taxAmount ?? 0,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
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
              child: _statusBar(approval, cancelReason),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Order detail layout helpers (same design as OrderDetailEnglish) ───
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
  Widget _heroTile(IconData icon, String label, String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    return Container(
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

  Widget _statusBar(int approval, String? cancelReason) {
    if (approval == 2) {
      return _statusBanner("accepted".tr, const Color(0xFF16A34A), Icons.check_circle_rounded);
    }
    if (approval == 3) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusBanner("decline".tr, const Color(0xFFDC2626), Icons.cancel_rounded),
          if (cancelReason != null && cancelReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${'cancel_reason'.tr}: $cancelReason',
                style: const TextStyle(fontFamily: 'Sora', 
                    fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFB91C1C)),
              ),
            ),
          ],
        ],
      );
    }
    return _statusBanner("pending".tr, const Color(0xFFF59E0B), Icons.hourglass_top_rounded);
  }

  Widget _orderItem(String title, double price, Items item) {
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
                      '${'currency'.tr} ${formatAmount(price)}',
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

  Widget _vatRow(String percentage, double brutto, double netto, double taxAmount) {
    const style = TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(percentage, style: style)),
          Expanded(child: Text(formatAmount(brutto), style: style, textAlign: TextAlign.right)),
          Expanded(child: Text(formatAmount(netto), style: style, textAlign: TextAlign.right)),
          Expanded(child: Text(formatAmount(taxAmount), style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}