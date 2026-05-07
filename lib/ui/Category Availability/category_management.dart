import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/category_availability_management_response_model.dart';
import '../../models/get_product_category_list_response_model.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<GetCategoryAvailabilityResponseModel> categoryAvailable = [];
  List<CategoryAvailabilityItem> flattenedAvailabilityList = [];
  TextEditingController openingTimeController = TextEditingController();
  TextEditingController closingTimeController = TextEditingController();
  List<int> selectedCategories = [];
  List<int> selectedDays = [];
  bool isActive = true;
  String? selectedLabel;

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  int currentPage = 1;
  int itemsPerPage = 8;
  int totalPages = 0;
  List<CategoryAvailabilityItem> currentPageItems = [];
  List<GetProductCategoryList> productCategoryList = [];

  void _updatePagination() {
    // Filter categories that have availability data
    flattenedAvailabilityList.clear();
    for (var category in categoryAvailable) {
      if (category.categoriesAvailability.isNotEmpty) {
        for (var availability in category.categoriesAvailability) {
          flattenedAvailabilityList.add(
            CategoryAvailabilityItem(
              categoryName: category.name,  // Yeh category ka naam show hoga
              categoryId: category.id,
              availability: availability,
            ),
          );
        }
      }
    }

    totalPages = (flattenedAvailabilityList.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    // Ensure current page is valid
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    // Get items for current page
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > flattenedAvailabilityList.length) endIndex = flattenedAvailabilityList.length;

    currentPageItems = flattenedAvailabilityList.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        _updatePagination();
      });
    }
  }

  List<int> _getPageNumbers() {
    List<int> pages = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      int start = currentPage - 2;
      int end = currentPage + 2;

      if (start < 1) {
        start = 1;
        end = 5;
      }

      if (end > totalPages) {
        end = totalPages;
        start = totalPages - 4;
      }

      for (int i = start; i <= end; i++) {
        pages.add(i);
      }
    }

    return pages;
  }

  String getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Unknown';
    }
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
      await getCategoryAvailability();
      await getProductCategory();
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
                    padding: const EdgeInsets.only(left: 10.0,right: 10 ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('category_availability'.tr,
                            style: const TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            showAddCategoryAvailabilityBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
                              child: Text('add'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    fontFamily: 'Mulish',
                                  )),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Showing entries info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${'showing'.tr} ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + currentPageItems.length} of ${flattenedAvailabilityList.length} ${'entries'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Mulish',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECF8FF),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.28,
                            child: Text('category_name'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  fontFamily: 'Mulish'),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.1,
                            child: Text('Days'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'Mulish')),
                          ),
                          const SizedBox(width: 15),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Center(
                              child: Text('open_time'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'Mulish'),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Center(
                              child: Text('close_time'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    fontFamily: 'Mulish'),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        final item = currentPageItems[index];
                        return Slidable(
                          key: ValueKey(item.availability.id),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.25,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showAddCategoryAvailabilityBottomSheet(
                                    isEditMode: true,
                                    availabilityData: item.availability,
                                  );
                                },
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: const BoxDecoration(
                                    color: Color(0xff0C831F),
                                  ),
                                  child: const Icon(
                                    Icons.mode_edit_outline_outlined,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDeleteDialog(
                                      context,
                                      item.categoryName,
                                      item.availability.id.toString()
                                  );
                                },
                                child: Container(
                                  width: 45,
                                  height: 45,
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
                            height: 55,
                            padding: const EdgeInsets.all(10),
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
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  child: Text(
                                    item.categoryName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.18,
                                  child: Text(
                                    getDayName(item.availability.dayOfWeek),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(

                                  width: MediaQuery.of(context).size.width * 0.25,
                                  child: Text(
                                    item.availability.startTime,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.15,
                                  child: Text(
                                    item.availability.endTime,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'Mulish'),
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

          if (flattenedAvailabilityList.isNotEmpty && totalPages > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    GestureDetector(
                      onTap: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage > 1 ? Colors.white : Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'previous'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage > 1 ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Page Numbers
                    ...(_getPageNumbers().map((pageNum) {
                      bool isActive = pageNum == currentPage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _goToPage(pageNum),
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0EA5E9) : Colors.white,
                              border: Border.all(
                                color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList()),

                    const SizedBox(width: 8),

                    // Next Button
                    GestureDetector(
                      onTap: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentPage < totalPages ? Colors.white : Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'next'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            color: currentPage < totalPages ? Colors.black87 : Colors.grey,
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

  Future<void> getProductCategory({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

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
      List<GetProductCategoryList> category = await CallService().getProductCategory(storeId!);

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          productCategoryList = category;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Product Category: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getCategoryAvailability({bool showLoader = true}) async {
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
      List<GetCategoryAvailabilityResponseModel> categoryAvailability = await CallService().getCategoryAvailability(storeId!);
      print('category availability length is ${categoryAvailability.length}');

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          categoryAvailable = categoryAvailability;
          currentPage = 1;
          _updatePagination();
          isLoading = false;
        });
      }
    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting category availability: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> addCategoryAvailability() async {
    // Validation
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('atleast_one'.tr), backgroundColor: Colors.red),
      );
      return false;
    }

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('atleast_day'.tr), backgroundColor: Colors.red),
      );
      return false;
    }

    if (openingTimeController.text.isEmpty || closingTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_open'.tr), backgroundColor: Colors.red),
      );
      return false;
    }

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      // Loop through each selected category and day
      for (int categoryId in selectedCategories) {
        for (int dayOfWeek in selectedDays) {
          var map = {
            "category_id": categoryId,
            "day_of_week": dayOfWeek,
            "start_time": "${openingTimeController.text}:00.000Z",  // Format: HH:mm:ss.SSSZ
            "end_time": "${closingTimeController.text}:00.000Z",
            "label": "Lunch",
            "isActive": true
          };

          await CallService().addCategoryAvailability(map);
        }
      }

      Get.back();
      await getCategoryAvailability(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('available_added'.tr), backgroundColor: Colors.green),
        );
      }
      return true;
    } catch (e) {
      Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_availablity'.tr), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  Future<bool> editCategoryAvailability(String availabilityId) async {
    // Validation
    if (selectedCategories.isEmpty || selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_day'.tr), backgroundColor: Colors.red),
      );
      return false;
    }

    if (openingTimeController.text.isEmpty || closingTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_open'.tr), backgroundColor: Colors.red),
      );
      return false;
    }

    Get.dialog(
      Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
      barrierDismissible: false,
    );

    try {
      var map = {
        "category_id": selectedCategories.first,
        "day_of_week": selectedDays.first,
        "start_time": "${openingTimeController.text}:00.000Z",
        "end_time": "${closingTimeController.text}:00.000Z",
        "label": "Lunch",
        "isActive": isActive  // Checkbox se value lenge
      };

      await CallService().editCategoryAvailability(map, availabilityId);
      Get.back();

      await getCategoryAvailability(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('avalaibe_update'.tr), backgroundColor: Colors.green),
        );
      }
      return true;
    } catch (e) {
      Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('available_failed'.tr), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  void showAddCategoryAvailabilityBottomSheet({
    bool isEditMode = false,
    CategoryAvailability? availabilityData,
  })
  {
    // Reset or populate fields
    if (isEditMode && availabilityData != null) {
      openingTimeController.text = availabilityData.startTime;
      closingTimeController.text = availabilityData.endTime;
      selectedLabel = availabilityData.label;
      isActive = availabilityData.isActive;
      selectedDays = [availabilityData.dayOfWeek];
      selectedCategories = [availabilityData.categoryId];
    } else {
      openingTimeController.clear();
      closingTimeController.clear();
      selectedCategories.clear();
      selectedDays.clear();
      isActive = true;
      selectedLabel = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 10,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditMode ? 'edit_availability'.tr : 'add_availability'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Select Categories Dropdown
                    Text(
                      'select_categories'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        _showCategorySelectionDialog(setModalState);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedCategories.isEmpty
                                    ? 'click'.tr
                                    : '${selectedCategories.length} ${'selected'.tr}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Mulish',
                                  color: selectedCategories.isEmpty ? Colors.grey : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Opening Time
                    Text(
                      'opening'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            openingTimeController.text =
                            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: openingTimeController,
                          decoration: InputDecoration(
                            hintText: '--:-- --',
                            suffixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Closing Time
                    Text(
                      'closing'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            closingTimeController.text =
                            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: closingTimeController,
                          decoration: InputDecoration(
                            hintText: '--:-- --',
                            suffixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Select Days
                    Text(
                      'days'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _buildDayButton('M', 1, setModalState),
                              _buildDayButton('T', 2, setModalState),
                              _buildDayButton('W', 3, setModalState),
                              _buildDayButton('T', 4, setModalState),
                              _buildDayButton('F', 5, setModalState),
                              _buildDayButton('S', 6, setModalState),
                              _buildDayButton('S', 0, setModalState),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (selectedDays.length == 7) {
                                selectedDays.clear();
                              } else {
                                selectedDays = [0, 1, 2, 3, 4, 5, 6];
                              }
                            });
                          },
                          child: Text(
                            'all'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Mulish',
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Active Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isActive,
                          onChanged: (value) {
                            setModalState(() {
                              isActive = value ?? true;
                            });
                          },
                        ),
                        Text(
                          'active'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'close'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (isEditMode && availabilityData != null) {
                                await editCategoryAvailability(availabilityData.id.toString());
                              } else {
                                await addCategoryAvailability();
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              isEditMode ? '${'update'.tr} (${selectedCategories.length})' : '${'addd'.tr} (${selectedCategories.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Day button widget
  Widget _buildDayButton(String day, int dayValue, StateSetter setModalState) {
    bool isSelected = selectedDays.contains(dayValue);
    return GestureDetector(
      onTap: () {
        setModalState(() {
          if (isSelected) {
            selectedDays.remove(dayValue);
          } else {
            selectedDays.add(dayValue);
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade400,
            width: 2,
          ),
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Mulish',
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Category selection dialog
  void _showCategorySelectionDialog(StateSetter setModalState) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('select_categories'.tr),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: productCategoryList.length,
                  itemBuilder: (context, index) {
                    final category = productCategoryList[index];
                    bool isSelected = selectedCategories.contains(category.id);
                    return CheckboxListTile(
                      title: Text(
                        category.name ?? 'unknown'.tr,
                        style: const TextStyle(fontFamily: 'Mulish'),
                      ),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          setModalState(() {
                            if (value == true) {
                              selectedCategories.add(category.id!);
                            } else {
                              selectedCategories.remove(category.id);
                            }
                          });
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteCategoryAvailability(String availabilityId) async {
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


      await CallService().deleteCategoryAvailability(availabilityId);

      Get.back();
      await getCategoryAvailability(showLoader: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('availability_deleted'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      Get.back();
      print('Error deleting availability: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_available'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void showDeleteDialog(BuildContext context, String categoryName, String availabilityId) {
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
                      '${'are'.tr} "$categoryName" ${'avail'.tr}?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          fontFamily: 'Mulish'
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
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(
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
                              deleteCategoryAvailability(availabilityId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
                              'delete'.tr,
                              style: const TextStyle(
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
              )
            ]
        ),
      ),
    );
  }



}

class CategoryAvailabilityItem {
  final String categoryName;
  final int categoryId;
  final CategoryAvailability availability;

  CategoryAvailabilityItem({
    required this.categoryName,
    required this.categoryId,
    required this.availability,
  });
}