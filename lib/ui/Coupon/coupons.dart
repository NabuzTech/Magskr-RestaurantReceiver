import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/get_coupons_response_model.dart';

class Coupon extends StatefulWidget {
  const Coupon({super.key});

  @override
  State<Coupon> createState() => _CouponState();
}

class _CouponState extends State<Coupon> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<GetCouponsResponseModel> couponAvailable = [];
  List<GetCouponsResponseModel> filteredCouponList = [];
  String currentSearchQuery = '';

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }


  void _editCoupon(int index) {
    GetCouponsResponseModel coupon = filteredCouponList[index];
    _showEditCouponBottomSheet(coupon);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
  }

  void _filterCoupons(String query) {
    setState(() {
      currentSearchQuery = query.toLowerCase();
      if (currentSearchQuery.isEmpty) {
        filteredCouponList = couponAvailable;
      } else {
        filteredCouponList = couponAvailable.where((coupon) {
          final name = (coupon.name ?? '').toLowerCase();
          final code = (coupon.code ?? '').toLowerCase();
          return name.contains(currentSearchQuery) || code.contains(currentSearchQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      await getCoupon();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(onSelectTab: _openTab),
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'coupon'.tr,
                          style: const TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showAddCouponBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Header Row
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          child: Text(
                            'name'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          child: Text(
                            'code'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          child:  Text(
                            'valid_date'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      Expanded(
                          child: Center(
                            child: Text(
                              'status'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (filteredCouponList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currentSearchQuery.isEmpty
                                ? 'no_coupon'.tr
                                : '${'no_match_found'.tr} "$currentSearchQuery"',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Mulish',
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCouponList.length,
                        itemBuilder: (context, index) {
                          var coupon = filteredCouponList[index];
                          return Slidable(
                            key: ValueKey(coupon.id ?? index),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.32,
                              children: [
                                // GestureDetector(
                                //   onTap: () => _editCoupon(index),
                                //   child: Container(
                                //     width: 60,
                                //     height: double.infinity,
                                //     decoration: const BoxDecoration(
                                //       color: Color(0xff0C831F),
                                //     ),
                                //     child: const Icon(
                                //       Icons.mode_edit_outline_outlined,
                                //       color: Colors.white,
                                //       size: 25,
                                //     ),
                                //   ),
                                // ),
                                GestureDetector(
                                  onTap: (){
                                    showDeleteCoupon(context,
                                        coupon.name.toString(), coupon.id.toString());
                                  },
                                  child: Container(
                                    width: 60,
                                    height: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: Color(0xffE25454),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    child: Text(
                                      coupon.name ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    child: Text(
                                      coupon.code ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.25,
                                    child: Text(
                                      coupon.endAt ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () {

                                          if (!(coupon.isActive ?? false)) {
                                            showActivateCoupon(context, coupon.name.toString(), coupon.id.toString());
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (coupon.isActive ?? false)
                                                ? const Color(0xff49B27A)
                                                : Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            (coupon.isActive ?? false) ? 'Active' : 'Inactive',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Mulish',
                                              fontWeight: FontWeight.w700,
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
                          );
                        },
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

  void _showAddCouponBottomSheet() {
    String? selectedCouponType;
    TextEditingController nameController = TextEditingController();
    TextEditingController codeController = TextEditingController();
    TextEditingController valueController = TextEditingController();
    TextEditingController minOrderController = TextEditingController();
    TextEditingController maxDiscountController = TextEditingController();
    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();

    bool validateCouponType = false;
    bool validateName = false;
    bool validateCode = false;
    bool validateValue = false;
    bool validateMinOrder = false;

    final List<String> couponTypes = ['fixed'.tr, 'free_delivery'.tr, 'perc'.tr, 'cart_threshold'.tr];

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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                height: MediaQuery.of(context).size.height * 0.8,
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
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'add_offer'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Coupon Type Dropdown
                            RichText(
                              text:  TextSpan(
                                text: 'coupon_type'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: validateCouponType ? Colors.red : Colors.grey.shade300,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCouponType,
                                  hint: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'select_coupon_type'.tr,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontFamily: 'Mulish',
                                      ),
                                    ),
                                  ),
                                  isExpanded: true,
                                  icon: const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(Icons.keyboard_arrow_down),
                                  ),
                                  items: couponTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          type,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Mulish',
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setModalState(() {
                                      selectedCouponType = newValue;
                                      validateCouponType = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Coupon Name
                            RichText(
                              text:  TextSpan(
                                text: 'coupon_name'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nameController,
                              onChanged: (value) {
                                if (validateName && value.isNotEmpty) {
                                  setModalState(() {
                                    validateName = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'title'.tr,
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Mulish',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateName ? Colors.red : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateName ? Colors.red : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateName ? Colors.red : const Color(0xFFFCAE03),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Add Code
                            RichText(
                              text: TextSpan(
                                text: 'add_code'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.black,
                                ),
                                children: const [
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: codeController,
                              onChanged: (value) {
                                if (validateCode && value.isNotEmpty) {
                                  setModalState(() {
                                    validateCode = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'add_code'.tr,
                                hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Mulish',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateCode ? Colors.red : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateCode ? Colors.red : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: validateCode ? Colors.red : const Color(0xFFFCAE03),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Coupon Value
                             Text(
                              'coupon_value'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: valueController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (validateValue && value.isNotEmpty) {
                                  setModalState(() {
                                    validateValue = false;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Min Order Amount and Max Discount Amount
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text:  TextSpan(
                                          text: 'min_order_amt'.tr,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Mulish',
                                            color: Colors.black,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: '*',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: minOrderController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          if (validateMinOrder && value.isNotEmpty) {
                                            setModalState(() {
                                              validateMinOrder = false;
                                            });
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontFamily: 'Mulish',
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: validateMinOrder ? Colors.red : Colors.grey.shade300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: validateMinOrder ? Colors.red : Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                              color: validateMinOrder ? Colors.red : const Color(0xFFFCAE03),
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    Text(
                                        'max_discount_amount'.tr,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: maxDiscountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontFamily: 'Mulish',
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                           // const SizedBox(height: 16),

                            // // Start Date and End Date
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: Column(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         children: [
                            //           const Text(
                            //             'Start Date',
                            //             style: TextStyle(
                            //               fontSize: 14,
                            //               fontWeight: FontWeight.w600,
                            //               fontFamily: 'Mulish',
                            //             ),
                            //           ),
                            //           const SizedBox(height: 8),
                            //           TextField(
                            //             controller: startDateController,
                            //             readOnly: true,
                            //             onTap: () async {
                            //               DateTime? pickedDate = await showDatePicker(
                            //                 context: context,
                            //                 initialDate: DateTime.now(),
                            //                 firstDate: DateTime.now(),
                            //                 lastDate: DateTime(2100),
                            //               );
                            //               if (pickedDate != null) {
                            //                 setModalState(() {
                            //                   startDateController.text =
                            //                   "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            //                 });
                            //               }
                            //             },
                            //             decoration: InputDecoration(
                            //               hintStyle: const TextStyle(
                            //                 color: Colors.grey,
                            //                 fontSize: 14,
                            //                 fontFamily: 'Mulish',
                            //               ),
                            //               suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            //               border: OutlineInputBorder(
                            //                 borderRadius: BorderRadius.circular(8),
                            //               ),
                            //               contentPadding: const EdgeInsets.symmetric(
                            //                 horizontal: 12,
                            //                 vertical: 12,
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //     const SizedBox(width: 12),
                            //     Expanded(
                            //       child: Column(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         children: [
                            //           const Text(
                            //             'End Date',
                            //             style: TextStyle(
                            //               fontSize: 14,
                            //               fontWeight: FontWeight.w600,
                            //               fontFamily: 'Mulish',
                            //             ),
                            //           ),
                            //           const SizedBox(height: 8),
                            //           TextField(
                            //             controller: endDateController,
                            //             readOnly: true,
                            //             onTap: () async {
                            //               DateTime? pickedDate = await showDatePicker(
                            //                 context: context,
                            //                 initialDate: DateTime.now(),
                            //                 firstDate: DateTime.now(),
                            //                 lastDate: DateTime(2100),
                            //               );
                            //               if (pickedDate != null) {
                            //                 setModalState(() {
                            //                   endDateController.text =
                            //                   "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            //                 });
                            //               }
                            //             },
                            //             decoration: InputDecoration(
                            //               hintStyle: const TextStyle(
                            //                 color: Colors.grey,
                            //                 fontSize: 14,
                            //                 fontFamily: 'Mulish',
                            //               ),
                            //               suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            //               border: OutlineInputBorder(
                            //                 borderRadius: BorderRadius.circular(8),
                            //               ),
                            //               contentPadding: const EdgeInsets.symmetric(
                            //                 horizontal: 12,
                            //                 vertical: 12,
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          //  const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Buttons
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF8E9AAF),
                                ),
                                child:  Center(
                                  child: Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Mulish',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async{
                                setModalState(() {
                                  validateCouponType = selectedCouponType == null;
                                  validateName = nameController.text.isEmpty;
                                  validateCode = codeController.text.isEmpty;
                                  validateMinOrder = minOrderController.text.isEmpty;
                                });

                                if (!validateCouponType &&
                                    !validateName &&
                                    !validateCode &&
                                    !validateValue &&
                                    !validateMinOrder) {
                                  // Add your API call here
                                  Navigator.pop(context);
                                  bool success = await addNewCoupon(
                                    couponType: selectedCouponType!,
                                    name: nameController.text,
                                    code: codeController.text,
                                    value: valueController.text,
                                    minCartAmount: minOrderController.text,
                                    maxDiscountAmount: maxDiscountController.text.isNotEmpty ? maxDiscountController.text : null,
                                    startDate: startDateController.text.isNotEmpty ? startDateController.text : null,
                                    endDate: endDateController.text.isNotEmpty ? endDateController.text : null,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF0C831F),
                                ),
                                child:  Center(
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
                    ),
                  ],
                ),
              ),
                Positioned(
                  top: -70,
                  right: 0,
                  left: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: const Icon(Icons.close, size: 25, color: Colors.black),
                      ),
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
  Future<bool> addNewCoupon({
    required String couponType,
    required String name,
    required String code,
    String? value,
    required String minCartAmount,
    String? maxDiscountAmount,
    String? startDate,
    String? endDate,
  }) async
  {
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store ID not found'), backgroundColor: Colors.red),
        );
      }
      return false;
    }

    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
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

    try {
      // Convert translated coupon type to English API value
      String apiCouponType;
      if (couponType == 'fixed'.tr) {
        apiCouponType = 'fixed';
      } else if (couponType == 'free_delivery'.tr) {
        apiCouponType = 'free_delivery';
      } else if (couponType == 'perc'.tr) {
        apiCouponType = 'percent';
      } else if (couponType == 'cart_threshold'.tr) {
        apiCouponType = 'cart_threshold';
      } else {
        // Fallback to lowercase with underscore
        apiCouponType = couponType.toLowerCase().replaceAll(' ', '_');
      }

      var map = {
        "store_id": storeId,
        "code": code,
        "name": name,
        "coupon_type": apiCouponType,
        "min_cart_amount": double.tryParse(minCartAmount) ?? 0,
      };
      if (value != null && value.isNotEmpty) {
        map["value"] = double.tryParse(value) ?? 0;
      }
      if (maxDiscountAmount != null && maxDiscountAmount.isNotEmpty) {
        map["max_discount_amount"] = double.tryParse(maxDiscountAmount) ?? 0;
      }

      if (startDate != null && startDate.isNotEmpty) {
        map["start_at"] = startDate;
      }

      if (endDate != null && endDate.isNotEmpty) {
        map["end_at"] = endDate;
      }
      print('coupon map is $map');
      final result = await Future.any([CallService().addNewCoupon(map),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);

      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (result == null) {
        throw Exception('Request timeout');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refresh coupon list
      await getCoupon(showLoader: false);

      return true;

    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      print('Error adding coupon: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add coupon: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> updateCoupon({
    required int couponId,
    required String couponType,
    required String name,
    required String code,
    required String value,
    required String minCartAmount,
    String? maxDiscountAmount,
    String? startDate,
    String? endDate,
  }) async
  {
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store ID not found'), backgroundColor: Colors.red),
        );
      }
      return false;
    }

    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 100));
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

    try {
      String apiCouponType = couponType.toLowerCase().replaceAll(' ', '_');

      var map = {
        "id": couponId,
        "store_id": storeId,
        "code": code,
        "name": name,
        "coupon_type": apiCouponType,
        "value": double.tryParse(value) ?? 0,
        "min_cart_amount": double.tryParse(minCartAmount) ?? 0,
      };

      if (maxDiscountAmount != null && maxDiscountAmount.isNotEmpty) {
        map["max_discount_amount"] = double.tryParse(maxDiscountAmount) ?? 0;
      }

      if (startDate != null && startDate.isNotEmpty) {
        map["start_at"] = startDate;
      }

      if (endDate != null && endDate.isNotEmpty) {
        map["end_at"] = endDate;
      }

      final result = await Future.any([
        //CallService().updateCoupon(map),
        Future.delayed(const Duration(seconds: 6)).then((_) => null)
      ]);

      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (result == null) {
        throw Exception('Request timeout');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await getCoupon(showLoader: false);

      return true;

    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      print('Error updating coupon: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update coupon: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  void _showEditCouponBottomSheet(GetCouponsResponseModel coupon) {
    String? selectedCouponType = coupon.couponType;
    TextEditingController nameController = TextEditingController(text: coupon.name);
    TextEditingController codeController = TextEditingController(text: coupon.code);
    TextEditingController valueController = TextEditingController(text: coupon.value?.toString() ?? '');
    TextEditingController minOrderController = TextEditingController(text: coupon.minCartAmount?.toString() ?? '');
    TextEditingController maxDiscountController = TextEditingController(text: coupon.maxDiscountAmount?.toString() ?? '');
    TextEditingController startDateController = TextEditingController(text: coupon.startAt ?? '');
    TextEditingController endDateController = TextEditingController(text: coupon.endAt ?? '');

    bool validateCouponType = false;
    bool validateName = false;
    bool validateCode = false;
    bool validateValue = false;
    bool validateMinOrder = false;

    final List<String> couponTypes = ['Fixed', 'Free Delivery', 'Percent', 'Cart Threshold'];

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
              height: MediaQuery.of(context).size.height * 0.85,
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
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Edit Offer Coupon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Same fields as Add Coupon...
                          // (Copy the entire fields section from Add Coupon)
                          // Coupon Type Dropdown
                          RichText(
                            text: const TextSpan(
                              text: 'Coupon Type',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Mulish',
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: validateCouponType ? Colors.red : Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCouponType,
                                hint: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '-- select coupon type--',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ),
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.keyboard_arrow_down),
                                ),
                                items: couponTypes.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setModalState(() {
                                    selectedCouponType = newValue;
                                    validateCouponType = false;
                                  });
                                },
                              ),
                            ),
                          ),
                          // ... rest of the fields (same as Add)
                        ],
                      ),
                    ),
                  ),

                  // Bottom Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF8E9AAF),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Mulish',
                                    color: Colors.white,
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
                              setModalState(() {
                                validateCouponType = selectedCouponType == null;
                                validateName = nameController.text.isEmpty;
                                validateCode = codeController.text.isEmpty;
                                validateValue = valueController.text.isEmpty;
                                validateMinOrder = minOrderController.text.isEmpty;
                              });

                              if (!validateCouponType &&
                                  !validateName &&
                                  !validateCode &&
                                  !validateValue &&
                                  !validateMinOrder) {

                                Navigator.pop(context);

                                bool success = await updateCoupon(
                                  couponId: coupon.id!,
                                  couponType: selectedCouponType!,
                                  name: nameController.text,
                                  code: codeController.text,
                                  value: valueController.text,
                                  minCartAmount: minOrderController.text,
                                  maxDiscountAmount: maxDiscountController.text.isNotEmpty ? maxDiscountController.text : null,
                                  startDate: startDateController.text.isNotEmpty ? startDateController.text : null,
                                  endDate: endDateController.text.isNotEmpty ? endDateController.text : null,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFF0C831F),
                              ),
                              child: const Center(
                                child: Text(
                                  'Save',
                                  style: TextStyle(
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void showDeleteCoupon(BuildContext context, String couponName, String couponId) {
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
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Are you sure you want to delete "$couponName"?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontFamily: 'Mulish',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 35,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E9AAF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        height: 35,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE25454),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            deleteCoupon(couponId);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                    color: Color(0xFFED4C5C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
    ),
    );
  }

  Future<void> getCoupon({bool showLoader = true}) async {
    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });

      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );
    }

    try {
      List<GetCouponsResponseModel> coupon = await CallService().getCoupons(storeId!);
      print('coupon length is ${coupon.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          couponAvailable=coupon;
          filteredCouponList=couponAvailable;
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting coupon: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteCoupon(String couponId) async {
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

    try {


      await CallService().deleteExistingCoupon(couponId);

      Get.back();
      await getCoupon(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ip_delete'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
      print('${'error_delete'.tr}: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_delete_ip'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void showActivateCoupon(BuildContext context, String couponName, String couponId) {
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
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Are you sure you want to activate "$couponName"?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      fontFamily: 'Mulish',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 35,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E9AAF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Container(
                        height: 35,
                        width: 85,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C831F),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            activateCoupon(couponId);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Activate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                    color: Color(0xFFED4C5C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> activateCoupon(String couponId) async {
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
    var map = {

    };
    try {
      await CallService().activateCoupon(couponId,map);

      Get.back();
      await getCoupon(showLoader: false);

    } catch (e) {
      Get.back();
      print('${'error_delete'.tr}: $e');
      }
    }
}

class CouponModel {
  final int id;
  final String name;
  final String code;
  final String validUntil;
  final bool isActive;
  CouponModel({
    required this.id,
    required this.name,
    required this.code,
    required this.validUntil,
    required this.isActive,
  });
}
