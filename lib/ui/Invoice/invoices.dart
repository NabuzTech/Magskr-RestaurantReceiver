import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/order_model.dart';
import '../home_screen.dart';

class Invoices extends StatefulWidget {
  const Invoices({super.key});

  @override
  State<Invoices> createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices> {
  SharedPreferences? sharedPreferences;
  String? bearerKey;
  String? storeId;

  bool isLoading = false;
  List<Order> orderList = [];
  DateTime selectedDate = DateTime.now();

  bool isMultiSelectMode = false;
  Set<int> selectedOrderIds = {};

  final ValueNotifier<int> _listRebuildNotifier = ValueNotifier<int>(0);

  void _openTab(int index) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.off(
        () => const HomeScreen(),
        arguments: {'initialTab': index},
        transition: Transition.noTransition,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  @override
  void dispose() {
    _listRebuildNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeAndFetch() async {
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences!.getString(valueShared_BEARER_KEY);
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (bearerKey == null || storeId == null) return;

    setState(() => isLoading = true);

    String date = DateFormat('yyyy-MM-dd').format(selectedDate);

    final Map<String, dynamic> data = {
      "store_id": storeId,
      "target_date": date,
      "limit": 0,
      "offset": 0,
    };

    try {
      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (!mounted) return;

      if (result.isNotEmpty && result.first.code != null) {
        setState(() {
          orderList = [];
          isLoading = false;
        });
        return;
      }

      setState(() {
        orderList = result;
        isLoading = false;
        _listRebuildNotifier.value++;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          orderList = [];
          isLoading = false;
        });
      }
    }
  }

  void _onDateSelected() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFCAE03),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isMultiSelectMode = false;
        selectedOrderIds.clear();
      });
      _fetchOrders();
    }
  }

  void _onLongPress(int orderId) {
    setState(() {
      isMultiSelectMode = true;
      selectedOrderIds.add(orderId);
    });
  }

  void _onTap(int orderId) {
    if (isMultiSelectMode) {
      setState(() {
        if (selectedOrderIds.contains(orderId)) {
          selectedOrderIds.remove(orderId);
          if (selectedOrderIds.isEmpty) {
            isMultiSelectMode = false;
          }
        } else {
          selectedOrderIds.add(orderId);
        }
      });
    }
  }

  void _cancelMultiSelect() {
    setState(() {
      isMultiSelectMode = false;
      selectedOrderIds.clear();
    });
  }

  void _deleteSelected() {
    if (selectedOrderIds.isEmpty) return;

    final selectedOrders = orderList
        .where((o) => selectedOrderIds.contains(o.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '${'delete_selected'.tr} (${selectedOrders.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mulish',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...selectedOrders.map((o) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      o.invoice?.invoiceNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPaymentTypeColor(o.payment?.paymentMethod).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPaymentTypeLabel(o.payment?.paymentMethod),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        color: _getPaymentTypeColor(o.payment?.paymentMethod),
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Text(
              'confirm_delete'.tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Mulish',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                fontFamily: 'Mulish',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBulkDelete(selectedOrderIds.toList());
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Mulish',
                color: Color(0xffE25454),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSingleDelete(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Order',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Mulish',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    order.invoice?.invoiceNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getPaymentTypeColor(order.payment?.paymentMethod).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPaymentTypeLabel(order.payment?.paymentMethod),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: _getPaymentTypeColor(order.payment?.paymentMethod),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'confirm_delete'.tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Mulish',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                fontFamily: 'Mulish',
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBulkDelete([order.id!]);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Mulish',
                color: Color(0xffE25454),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkDelete(List<int> orderIds) async {
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

    try {
      final result = await CallService().deleteBulkOrder(orderIds);

      print("delete bulk orderId is $orderIds");
      if (Get.isDialogOpen ?? false) Get.back();

      if (result.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          isMultiSelectMode = false;
          selectedOrderIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.deleted?.length ?? 0} order(s) deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _fetchOrders();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _updatePaymentMethod(Order order, String newPaymentType) async {
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

    try {
      final body = {"payment_method": newPaymentType};
      await CallService().updatePaymentMethod(body, order.id.toString());

      if (Get.isDialogOpen ?? false) Get.back();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _fetchOrders();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'update_failed'.tr}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getPaymentTypeLabel(String? method) {
    if (method == null) return 'N/A';
    switch (method.toLowerCase()) {
      case 'cash':
        return 'cash'.tr;
      case 'stripe':
        return 'Stripe';
      case 'paypal':
        return 'PayPal';
      default:
        return method;
    }
  }

  Color _getPaymentTypeColor(String? method) {
    if (method == null) return Colors.grey;
    switch (method.toLowerCase()) {
      case 'cash':
        return const Color(0xff0C831F);
      case 'stripe':
        return const Color(0xff635BFF);
      case 'paypal':
        return const Color(0xff003087);
      default:
        return Colors.grey;
    }
  }

  void _showEditBottomSheet(Order order) {
    String selectedPaymentType =
        order.payment?.paymentMethod?.toLowerCase() ?? 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'edit_invoice'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                      'invoice_number'.tr,
                      order.invoice?.invoiceNumber ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'order_id'.tr, '#${order.orderNumber ?? order.id ?? 'N/A'}'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'amount'.tr,
                      '€${order.invoice?.totalAmount?.toStringAsFixed(2) ?? '0.00'}'),
                  const SizedBox(height: 20),
                  Text(
                    'payment_type'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['cash', 'stripe', 'paypal'].map((type) {
                      bool isSelected = selectedPaymentType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPaymentType = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getPaymentTypeColor(type)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? _getPaymentTypeColor(type)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getPaymentTypeLabel(type),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                'cancel'.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (selectedPaymentType == (order.payment?.paymentMethod?.toLowerCase() ?? 'cash')) {
                              Navigator.pop(context);
                              return;
                            }
                            Navigator.pop(context);
                            await _updatePaymentMethod(order, selectedPaymentType);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
                              child: Text(
                                'saved'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Mulish',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Mulish',
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width*0.5,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'invoices'.tr,
                  style: const TextStyle(
                    fontFamily: 'Mulish',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _fetchOrders,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF8FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.refresh, size: 18, color: Color(0xFF1976D2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _onDateSelected,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB3DEFF)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Color(0xFF1976D2)),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: Lottie.asset(
                      'assets/animations/burger.json',
                      width: 120,
                      height: 120,
                      repeat: true,
                    ),
                  )
                : orderList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'no_invoices_today'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Mulish',
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFFCAE03),
                        onRefresh: _fetchOrders,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _listRebuildNotifier,
                          builder: (context, value, child) {
                            return SlidableAutoCloseBehavior(
                              key: ValueKey(value),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                itemCount: orderList.length,
                                itemBuilder: (context, index) {
                                  final order = orderList[index];
                                  final orderId = order.id ?? 0;
                                  final isSelected =
                                      selectedOrderIds.contains(orderId);

                                  if (isMultiSelectMode) {
                                    return _buildSelectableCard(
                                        order, isSelected);
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Slidable(
                                        key: ValueKey(orderId),
                                        endActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          extentRatio: 0.35,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showEditBottomSheet(order),
                                              child: Container(
                                                width: 55,
                                                height: double.infinity,
                                                margin: const EdgeInsets.only(left: 3),
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(7),
                                                      bottomLeft: Radius.circular(7),
                                                  ),
                                                  color: Color(0xff0C831F),
                                                ),
                                                child: const Icon(
                                                  Icons.mode_edit_outline_outlined,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _confirmSingleDelete(order),
                                              child: Container(
                                                width: 55,
                                                height: double.infinity,
                                                decoration: const BoxDecoration(
                                                  borderRadius: BorderRadius.only(
                                                    topRight: Radius.circular(7),
                                                    bottomRight: Radius.circular(7),
                                                  ),
                                                  color: Color(0xffE25454),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: GestureDetector(
                                          onLongPress: () =>
                                              _onLongPress(orderId),
                                          onTap: () => _onTap(orderId),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(7),
                                              border: Border.all(
                                                color: _getPaymentTypeColor(order.payment?.paymentMethod).withValues(alpha: 0.4),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  spreadRadius: 0,
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: _buildOrderCardContent(order),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (isMultiSelectMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _cancelMultiSelect,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              'cancel'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: _deleteSelected,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xffE25454),
                          ),
                          child: Center(
                            child: Text(
                              '${'delete_selected'.tr} (${selectedOrderIds.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectableCard(Order order, bool isSelected) {
    return GestureDetector(
      onTap: () => _onTap(order.id ?? 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFCAE03)
                : _getPaymentTypeColor(order.payment?.paymentMethod).withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 4, right: 10),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFCAE03)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFCAE03)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              Expanded(child: _buildOrderCardContent(order)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCardContent(Order order) {
    final invoiceNumber = order.invoice?.invoiceNumber ?? 'N/A';
    final orderNumber = order.orderNumber ?? order.id;
    final paymentMethod = order.payment?.paymentMethod;
    final amount = order.invoice?.totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               Padding(
                 padding: const EdgeInsets.only(top: 4.0),
                 child: SvgPicture.asset('assets/images/invoice.svg'),
               ),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Text(
                    invoiceNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Mulish',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getPaymentTypeColor(paymentMethod).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getPaymentTypeLabel(paymentMethod),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: _getPaymentTypeColor(paymentMethod),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '€${amount?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFamily: 'Mulish',
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Text(
                  '${'order_number'.tr}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    fontFamily: 'Mulish',
                  ),
                ),
                Text(
                  '${orderNumber ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    fontFamily: 'Mulish',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> updateOrderPaymentMethod({
    required int orderId,
   required String payment,
  }) async
  {
    if (sharedPreferences == null) return false;

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "payment_method": "cash"
      };
      print("Update payment method Map: $map");
      await CallService().updatePaymentMethod(map,orderId.toString());
      if (Get.isDialogOpen ?? false) Get.back();
      await _fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('zone_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2)));
      }
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Update payment method  error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'failed_create'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2)));
      }
      return false;
    }
  }
}
