import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_delivery_zone_response_model.dart';

class DeliveryZone extends StatefulWidget {
  const DeliveryZone({super.key});

  @override
  State<DeliveryZone> createState() => _DeliveryZoneState();
}

class _DeliveryZoneState extends State<DeliveryZone> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<GetDeliveryZoneResponseModel> deliveryZone = [];

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      return;
    }
  }

  void _editZone(int index) {
    showAddDeliveryZoneBottomSheet(
      isEditMode: true,
      zoneData: deliveryZone[index],
    );
  }

  void _deleteZone(int index) {
    showDeleteZoneDialog(context, deliveryZone[index].id!);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getDeliveryZone();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'delivery_zone'.tr,
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showAddDeliveryZoneBottomSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: const Color(0xFFFCAE03),
                      ),
                      child: Text(
                        'add'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Table Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(color: Color(0xFFECF8FF)),
              child: Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.18,
                    child: Text('min_dist'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Mulish')),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.18,
                    child: Text('max_dist'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Mulish')),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.20,
                    child: Text('min_Amount'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Mulish')),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.18,
                    child: Text('del_fee'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Mulish')),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: Center(
                      child: Text('status'.tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              fontFamily: 'Mulish')),
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            deliveryZone.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'no_data'.tr,
                        style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Mulish',
                            color: Colors.grey[500]),
                      ),
                    ),
                  )
                : SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: deliveryZone.length,
                      itemBuilder: (context, index) {
                        final zone = deliveryZone[index];
                        return Slidable(
                          key: ValueKey(index),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.25,
                            children: [
                              GestureDetector(
                                onTap: () => _editZone(index),
                                child: Container(
                                  width: 45,
                                  height: double.infinity,
                                  decoration: const BoxDecoration(
                                      color: Color(0xff0C831F)),
                                  child: const Icon(
                                      Icons.mode_edit_outline_outlined,
                                      color: Colors.white,
                                      size: 25),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _deleteZone(index),
                                child: Container(
                                  width: 45,
                                  height: double.infinity,
                                  decoration: const BoxDecoration(
                                      color: Color(0xffE25454)),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.white, size: 25),
                                ),
                              ),
                            ],
                          ),
                          child: Container(
                            height: 55,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  child: Text(
                                    '${zone.minDistance ?? 'N/A'} km',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  child: Text(
                                    '${zone.maxDistance ?? 'N/A'} km',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.20,
                                  child: Text(
                                    '${"currency".tr} ${zone.minimumOrderAmount ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  child: Text(
                                    '${"currency".tr} ${zone.deliveryFee ?? 'N/A'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (zone.isActive ?? false)
                                            ? const Color(0xFFE6F9EE)
                                            : const Color(0xFFFFEEEE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (zone.isActive ?? false)
                                            ? 'active'.tr
                                            : 'inactive'.tr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Mulish',
                                          fontWeight: FontWeight.w700,
                                          color: (zone.isActive ?? false)
                                              ? const Color(0xFF0C831F)
                                              : const Color(0xFFE25454),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Sheet ─────────────────────────────────────────────────────────────

  void showAddDeliveryZoneBottomSheet({
    bool isEditMode = false,
    GetDeliveryZoneResponseModel? zoneData,
  })
  {
    TextEditingController minDistanceController = TextEditingController(
        text: isEditMode ? zoneData?.minDistance?.toString() ?? '' : '');
    TextEditingController maxDistanceController = TextEditingController(
        text: isEditMode ? zoneData?.maxDistance?.toString() ?? '' : '');
    TextEditingController minimumOrderController = TextEditingController(
        text: isEditMode ? zoneData?.minimumOrderAmount?.toString() ?? '' : '');
    TextEditingController deliveryFeeController = TextEditingController(
        text: isEditMode ? zoneData?.deliveryFee?.toString() ?? '' : '');
    TextEditingController deliveryTimeController = TextEditingController(
        text: isEditMode ? zoneData?.deliveryTime?.toString() ?? '' : '');
    bool isActive = isEditMode ? (zoneData?.isActive ?? true) : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEditMode ? 'edit_zone'.tr : 'add_zone'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              _buildLabel('min_dist'.tr),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  controller: minDistanceController,
                                  hint: 'enter_min_dist'.tr,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              _buildLabel('max_dist'.tr),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  controller: maxDistanceController,
                                  hint: 'enter_max_dist'.tr,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              _buildLabel('min_order'.tr),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  controller: minimumOrderController,
                                  hint: 'enter_min'.tr,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              _buildLabel('del_fee'.tr),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  controller: deliveryFeeController,
                                  hint: 'enter_del'.tr,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              _buildLabel('del_min'.tr),
                              const SizedBox(height: 8),
                              _buildTextField(
                                  controller: deliveryTimeController,
                                  hint: 'enter_del_time'.tr,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('is_active'.tr,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Mulish')),
                                  Switch(
                                    value: isActive,
                                    activeColor: const Color(0xFFFCAE03),
                                    onChanged: (val) => setModalState(() => isActive = val),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black.withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text('close'.tr,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Mulish')),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  SizedBox(
                                    width: 180,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (minDistanceController.text.isEmpty) {
                                          _showSnack(context, 'enter_min_dist'.tr);
                                          return;
                                        }
                                        if (maxDistanceController.text.isEmpty) {
                                          _showSnack(context, 'enter_max_dist'.tr);
                                          return;
                                        }
                                        if (minimumOrderController.text.isEmpty) {
                                          _showSnack(context, 'ent_min'.tr);
                                          return;
                                        }
                                        if (deliveryFeeController.text.isEmpty) {
                                          _showSnack(context, 'ent_del'.tr);
                                          return;
                                        }
                                        if (deliveryTimeController.text.isEmpty) {
                                          _showSnack(context, 'ent_del_time'.tr);
                                          return;
                                        }
                                        Navigator.pop(context);
                                        if (isEditMode) {
                                          await updateDeliveryZone(
                                            zoneId: zoneData!.id!,
                                            minDistance: minDistanceController.text,
                                            maxDistance: maxDistanceController.text,
                                            minimumOrderAmount: minimumOrderController.text,
                                            deliveryFee: deliveryFeeController.text,
                                            deliveryTime: deliveryTimeController.text,
                                            isActive: isActive,
                                          );
                                        } else
                                        {
                                          await addDeliveryZone(
                                            minDistance: minDistanceController.text,
                                            maxDistance: maxDistanceController.text,
                                            minimumOrderAmount: minimumOrderController.text,
                                            deliveryFee: deliveryFeeController.text,
                                            deliveryTime: deliveryTimeController.text,
                                            isActive: isActive,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFCAE03),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(isEditMode
                                            ? 'update'.tr : 'add_zone'.tr,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Mulish'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -22,
                  right: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                      ),
                      child: const Icon(Icons.close,
                          size: 25, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Reusable Widgets ─────────────────────────────────────────────────────────

  Widget _buildLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Mulish'));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFCAE03))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ─── Delete Dialog ────────────────────────────────────────────────────────────

  void showDeleteZoneDialog(BuildContext context, int zoneId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text('delete_zone_confirm'.tr,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          fontFamily: 'Mulish'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 35,
                        width: 70,
                        decoration: BoxDecoration(
                            color: const Color(0xFF8E9AAF),
                            borderRadius: BorderRadius.circular(3)),
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3))),
                          child: Text('cancel'.tr,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        height: 35,
                        width: 70,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE25454),
                            borderRadius: BorderRadius.circular(3)),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            deleteDeliveryZone(zoneId);
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3))),
                          child: Text('delete'.tr,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -20,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Color(0xFFED4C5C), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── API Methods ──────────────────────────────────────────────────────────────

  Future<void> getDeliveryZone({bool showLoader = true}) async {
    if (sharedPreferences == null) return;
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    if (showLoader && mounted) {
      setState(() => isLoading = true);
      Get.dialog(
        Center(
            child: Lottie.asset('assets/animations/burger.json',
                width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );
    }

    try {
      List<GetDeliveryZoneResponseModel> model =
          await CallService().getDeliveryZone(storeId!);
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
      if (mounted) {
        setState(() {
          deliveryZone = model;
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader && (Get.isDialogOpen ?? false)) Get.back();
      print('Error getting Delivery Zone: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> addDeliveryZone({
    required String minDistance,
    required String maxDistance,
    required String minimumOrderAmount,
    required String deliveryFee,
    required String deliveryTime,
    required bool isActive,
  }) async
  {
    if (sharedPreferences == null) return false;
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) return false;

    Get.dialog(
      Center(
          child: Lottie.asset('assets/animations/burger.json',
              width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "min_distance": double.tryParse(minDistance),
        "max_distance": double.tryParse(maxDistance),
        "minimum_order_amount": double.tryParse(minimumOrderAmount),
        "delivery_fee": double.tryParse(deliveryFee),
        "delivery_time": double.tryParse(deliveryTime),
        "is_active": isActive,
        "store_id": int.tryParse(storeId!),
      };
      print("Add Delivery Zone Map: $map");
      await CallService().addDeliveryZone(map);
      if (Get.isDialogOpen ?? false) Get.back();
      await getDeliveryZone(showLoader: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('zone_created'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2)));
      }
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Add Delivery Zone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'failed_create'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2)));
      }
      return false;
    }
  }

  Future<bool> updateDeliveryZone({
    required int zoneId,
    required String minDistance,
    required String maxDistance,
    required String minimumOrderAmount,
    required String deliveryFee,
    required String deliveryTime,
    required bool isActive,
  }) async
  {
    if (sharedPreferences == null) return false;

    Get.dialog(
      Center(
          child: Lottie.asset('assets/animations/burger.json',
              width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "min_distance": double.tryParse(minDistance),
        "max_distance": double.tryParse(maxDistance),
        "minimum_order_amount": double.tryParse(minimumOrderAmount),
        "delivery_fee": double.tryParse(deliveryFee),
        "delivery_time": double.tryParse(deliveryTime),
          "is_active": isActive,
      };
      print("Update Delivery Zone Map: $map");
       await CallService().updateDeliveryZone(map,zoneId.toString());
      if (Get.isDialogOpen ?? false) Get.back();
      await getDeliveryZone(showLoader: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('zone_updated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2)));
      }
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Update Delivery Zone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${'failed_create'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2)));
      }
      return false;
    }
  }

  Future<void> deleteDeliveryZone(int zoneId) async {
    Get.dialog(
      Center(
          child: Lottie.asset('assets/animations/burger.json',
              width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
        await CallService().deleteDeliveryZone(zoneId.toString());
      if (Get.isDialogOpen ?? false) Get.back();
      await getDeliveryZone(showLoader: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('zone_deleted'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2)));
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print('Delete Delivery Zone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('zone_delete_failed'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2)));
      }
    }
  }
}
