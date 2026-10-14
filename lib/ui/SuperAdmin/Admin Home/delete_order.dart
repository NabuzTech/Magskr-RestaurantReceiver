import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../api/repository/api_repository.dart';
import '../../../customView/payment_icon.dart';
import '../../../models/order_history_response_model.dart';
import '../../Order_history/order_history_details.dart';

// Same palette as OrderScreen
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

class DeleteOrder extends StatefulWidget {
  final int storeId;
  final String? storeName;
  const DeleteOrder({super.key, required this.storeId, this.storeName});

  @override
  State<DeleteOrder> createState() => _DeleteOrderState();
}

class _DeleteOrderState extends State<DeleteOrder> {
  List<orderHistoryResponseModel> ordersList = [];
  DateTime selectedDate = DateTime.now();
  bool showCalendar = false;
  int displayedMonth = DateTime.now().month;
  int displayedYear = DateTime.now().year;
  final Set<int> selectedOrderIds = {};

  bool get isMultiSelectMode => selectedOrderIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => orderHistory());
  }

  void _showLoader() {
    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );
  }

  void _hideLoader() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Sora')), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> orderHistory() async {
    final map = {
      "store_id": widget.storeId,
      "target_date": DateFormat('yyyy-MM-dd').format(selectedDate),
      "offset": 0,
    };
    _showLoader();
    try {
      final orders = await CallService().orderHistory(map);
      _hideLoader();
      if (!mounted) return;
      setState(() {
        ordersList = orders;
        selectedOrderIds.clear();
      });
    } catch (e) {
      _hideLoader();
      _showSnack('${'during'.tr}: $e', Colors.red);
    }
  }

  Future<bool> _confirm(String message) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700)),
        content: Text(message, style: const TextStyle(fontFamily: 'Sora')),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Sora'))),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Sora', color: Color(0xffE25454))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteSingle(orderHistoryResponseModel order) async {
    if (order.id == null) return;
    if (!await _confirm('Delete order ${order.orderNumber}?')) return;
    _showLoader();
    final ok = await CallService().deleteOrder(order.id!);
    _hideLoader();
    if (!ok) {
      _showSnack('Failed to delete order', Colors.red);
      return;
    }
    setState(() {
      ordersList.removeWhere((o) => o.id == order.id);
      selectedOrderIds.remove(order.id);
    });
    _showSnack('Order deleted', Colors.green);
  }

  Future<void> _deleteSelected() async {
    final ids = selectedOrderIds.toList();
    if (!await _confirm('Delete ${ids.length} selected order(s)?')) return;
    _showLoader();
    final result = await CallService().deleteBulkOrder(ids);
    _hideLoader();
    if (result.error != null) {
      _showSnack(result.error!, Colors.red);
      return;
    }
    final deleted = (result.deleted ?? ids).toSet();
    setState(() {
      ordersList.removeWhere((o) => deleted.contains(o.id));
      selectedOrderIds.clear();
    });
    _showSnack('${deleted.length} order(s) deleted', Colors.green);
  }

  void _toggleSelection(orderHistoryResponseModel order) {
    if (order.id == null) return;
    setState(() {
      if (!selectedOrderIds.remove(order.id)) selectedOrderIds.add(order.id!);
    });
  }

  String formatAmount(double amount) {
    final localeToUse = (Get.locale?.languageCode ?? 'en') == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.0#', localeToUse).format(amount);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMultiSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(selectedOrderIds.clear);
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _kPageGradient),
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: isMultiSelectMode
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(selectedOrderIds.clear))
              : null,
          title: Text(
            isMultiSelectMode ? '${selectedOrderIds.length} selected' : (widget.storeName ?? 'Delete Order'),
            style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (isMultiSelectMode) ...[
              IconButton(
                icon: Icon(selectedOrderIds.length == ordersList.length ? Icons.deselect : Icons.select_all),
                onPressed: () => setState(() {
                  if (selectedOrderIds.length == ordersList.length) {
                    selectedOrderIds.clear();
                  } else {
                    selectedOrderIds.addAll(ordersList.where((o) => o.id != null).map((o) => o.id!));
                  }
                }),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xffE25454)), onPressed: _deleteSelected),
            ] else ...[
              IconButton(
                icon: Icon(showCalendar ? Icons.close : Icons.calendar_month),
                onPressed: () => setState(() {
                  showCalendar = !showCalendar;
                  displayedMonth = selectedDate.month;
                  displayedYear = selectedDate.year;
                }),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: orderHistory),
            ],
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID : ${widget.storeId}  •  ${DateFormat('d MMMM, y').format(selectedDate)}',
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${'total_order'.tr}: ${ordersList.length}',
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (showCalendar) ...[_calendar(), const SizedBox(height: 10)],
              Expanded(child: _orderList()),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _orderList() {
    if (ordersList.isEmpty) {
      return RefreshIndicator(
        onRefresh: orderHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            Lottie.asset('assets/animations/empty.json', width: 150, height: 150),
            Center(
              child: Text('no_order'.tr,
                  style: const TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: orderHistory,
      color: _kPurple,
      child: SlidableAutoCloseBehavior(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            final order = ordersList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Slidable(
                key: ValueKey(order.id ?? index),
                enabled: !isMultiSelectMode,
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.2,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (slideContext) => GestureDetector(
                          onTap: () {
                            Slidable.of(slideContext)?.close();
                            _deleteSingle(order);
                          },
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(color: const Color(0xffE25454), borderRadius: BorderRadius.circular(7)),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                child: _orderCard(order),
              ),
            );
          },
        ),
      ),
    );
  }

  String _extractTime(String deliveryTime) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(deliveryTime));
    } catch (_) {
      return deliveryTime;
    }
  }

  bool _isVorbestellen(String? deliveryTime) {
    if (deliveryTime == null || deliveryTime.isEmpty) return false;
    final d = DateTime.tryParse(deliveryTime);
    return d != null && !DateUtils.isSameDay(d, DateTime.now());
  }

  Widget _sourceBadge(String source) {
    final (String label, Color color) = switch (source.toLowerCase()) {
      'mobile user app' => ('Magskr', _kIndigo),
      'online' => ('Website', const Color(0xFFFFC107)),
      'pos' => ('POS', const Color(0xFF1976D2)),
      _ => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Sora', fontSize: 13)),
    );
  }

  Widget _orderCard(orderHistoryResponseModel order) {
    final isSelected = selectedOrderIds.contains(order.id);
    final time = DateFormat('hh:mm a').format(DateTime.parse(order.createdAt.toString()));
    final guest = order.guestShippingJson;
    final shipping = order.shippingAddress;
    final source = order.source.toString();
    final isPos = source.toLowerCase() == 'pos';
    final address = order.orderType == 1
        ? (shipping != null ? '${shipping.line1 ?? ''}, ${shipping.city ?? ''}' : '${guest?.line1 ?? ''}, ${guest?.city ?? ''}')
        : '';

    final Color background = isSelected
        ? _kPurple.withValues(alpha: 0.12)
        : isPos
            ? const Color(0xffF7F3FF)
            : order.approvalStatus == 2
                ? const Color(0xffF3EEFF)
                : order.approvalStatus == 3
                    ? const Color(0xffFFEFEF)
                    : Colors.white;
    final Color border = isSelected
        ? _kPurple
        : isPos
            ? const Color(0xffB8ABD1)
            : order.approvalStatus == 2
                ? const Color(0xffD9CCFB)
                : order.approvalStatus == 3
                    ? const Color(0xffFFD0D0)
                    : Colors.grey.withValues(alpha: 0.2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => isMultiSelectMode ? _toggleSelection(order) : Get.to(() => OrderHistoryDetails(historyOrder: order)),
      onLongPress: () => _toggleSelection(order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border, width: isSelected ? 1.5 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMultiSelectMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 6),
                    child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? _kPurple : Colors.grey, size: 22),
                  ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              order.orderType == 2 ? 'pickup'.tr : (shipping?.zip?.toString() ?? guest?.zip?.toString() ?? ''),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Sora'),
                            ),
                          ),
                          if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Text('${'time'.tr}: ${_extractTime(order.deliveryTime!)}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Sora')),
                          ],
                        ],
                      ),
                      if (address.isNotEmpty)
                        Text(address, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, fontFamily: 'Sora')),
                    ],
                  ),
                ),
                _sourceBadge(source),
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
                    '${shipping?.customerName ?? guest?.customerName ?? ''} / ${shipping?.phone ?? guest?.phone ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Sora', fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${'order_number'.tr} : ${order.orderNumber ?? order.id ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Sora')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text('${'currency'.tr} ${formatAmount(order.payment?.amount ?? 0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Sora', fontSize: 16)),
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

  // Month grid, same layout as ReportScreen._calendar
  Widget _calendar() {
    final startWeekday = DateTime(displayedYear, displayedMonth, 1).weekday % 7;
    final totalDays = DateTime(displayedYear, displayedMonth + 1, 0).day;
    final totalCells = ((startWeekday + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                displayedMonth = displayedMonth == 1 ? 12 : displayedMonth - 1;
                if (displayedMonth == 12) displayedYear--;
              }),
            ),
            Text(DateFormat('MMMM y').format(DateTime(displayedYear, displayedMonth)),
                style: const TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                displayedMonth = displayedMonth == 12 ? 1 : displayedMonth + 1;
                if (displayedMonth == 1) displayedYear++;
              }),
            ),
          ],
        ),
        Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          children: [
            TableRow(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((d) => Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Center(
                            child: Text(d,
                                style: const TextStyle(fontFamily: 'Sora', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                      ))
                  .toList(),
            ),
            ...List.generate(totalCells ~/ 7, (week) {
              return TableRow(
                children: List.generate(7, (dayIndex) {
                  // DateTime normalises out-of-range days into prev/next month
                  final date = DateTime(displayedYear, displayedMonth, week * 7 + dayIndex - startWeekday + 1);
                  final isCurrentMonth = date.month == displayedMonth;
                  final isSelected = DateUtils.isSameDay(date, selectedDate);
                  final isFuture = date.isAfter(today);
                  return GestureDetector(
                    onTap: isFuture
                        ? null
                        : () {
                            setState(() {
                              selectedDate = date;
                              showCalendar = false;
                            });
                            orderHistory();
                          },
                    child: Container(
                      height: 45,
                      color: isSelected ? _kPurple : Colors.white,
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth && !isFuture)
                                  ? Colors.black
                                  : Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ],
    );
  }
}
