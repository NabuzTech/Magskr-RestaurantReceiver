import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';
import '../../Database/databse_helper.dart';
import '../../api/Socket/reservation_socket_service.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../controller/AppController.dart';
import '../../models/OrderItem.dart';
import '../../models/Payment.dart';
import '../../models/ShippingAddress.dart';
import '../../models/Topping.dart';
import '../../models/get_discount_percentage_response_model.dart';
import '../../models/get_product_category_list_response_model.dart';
import '../../models/get_store_postcode_response_model.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/get_store_timing_response_model.dart';
import '../../models/order_model.dart';
import '../../models/sync_order_response_model.dart';
import '../../api/Socket/socket_service.dart';
import '../../utils/my_application.dart';

class PosController extends GetxController {

// Observable variables - Landscape Mode
  final selectedCategoryIndex = 0.obs;
  final selectedProductIndex = Rx<int?>(null);
  final orderNote = ''.obs;
  final selectedOrderType = 'Lieferzeit'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isCartExpanded = true.obs;
  final showCustomerDetails = false.obs;
  final isCustomerFormVisible = true.obs;
  final isRefreshing = false.obs;
  final showOrderOverlay = false.obs;
  final showDraftPanel = false.obs;
  final drafts = <Map<String, dynamic>>[].obs;
// Cart management - Landscape
  final cartItems = <Map<String, dynamic>>[].obs;
  final customerDetails = <String, String>{}.obs;

// Portrait Mode Variables
  final isSearching = false.obs;
  final cart = <String, CartItem>{}.obs;
  final totalPrice = 0.0.obs;
  final totalItems = 0.obs;

// Lists
  final productCategoryList = <GetProductCategoryList>[].obs;
  final productList = <GetStoreProducts>[].obs;
  final postcode = <GetStorePostCodesResponseModel>[].obs;
  final filteredProducts = <GetStoreProducts>[].obs;
  final categories = <CategoryData>[].obs;
  final discountPercentage = 0.0.obs;
  final deliveryDiscount = 0.0.obs;
  final pickupDiscount = 0.0.obs;
  String? deliveryDiscountId;
  String? pickupDiscountId;
  List<GetDiscountPercentageResponseModel> currentDiscounts = [];

// Controllers
  final noteController = TextEditingController();
  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final regionController = TextEditingController();

// Scroll controllers - Portrait
  final mainScrollController = ScrollController();
  final sidebarScrollController = ScrollController();

  final visibleCategories = <int>[].obs;
  final lastScrollPosition = 0.0.obs;
  final ItemScrollController landscapeProductScrollController = ItemScrollController();
  final ItemPositionsListener landscapeProductPositionsListener = ItemPositionsListener.create();
  final landscapeCategoryScrollController = ScrollController();
  final isAutoScrolling = false.obs;

  final selectedProduct = Rx<GetStoreProducts?>(null);
  final selectedVariant = Rx<Variants?>(null);
  final selectedToppings = <String>[].obs;
  final showVariantDialog = false.obs;
  final expandedVariantId = Rx<int?>(null);
  final selectedToppingsMap = <int, List<int>>{}.obs;

  final selectedPostcode = Rx<GetStorePostCodesResponseModel?>(null);
  final showPostcodeDialog = false.obs;
  final List<Map<String, String>> sofortTimeSlots = <Map<String, String>>[].obs;
  final storeOpeningTime = Rx<DateTime?>(null);
  final SocketService _socketService = SocketService();
  final SocketServices oderSocketService = SocketServices();

  List<GetStoreTimingResponseModel> storeTimingList = [];
  final selectedVorbestellenDate = Rx<DateTime?>(null);

  final nameFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final addressFocusNode = FocusNode();
  final regionFocusNode = FocusNode();

  final isHeuteSelected = true.obs;
  final isVorbestellenSelected = false.obs;
  final selectedDate = Rx<DateTime?>(null);
  final showCalendar = false.obs;
  final showTimeSelector = false.obs;

  String? storeId;
  SharedPreferences? sharedPreferences;
  final isScrollingProgrammatically = false.obs;
  List<GlobalKey> categoryKeys = [];
  final invoiceNumber = 1.obs;
  final selectedSaveOption = ''.obs;
  final selectedTimeSlot = 'sofort'.obs;
  final showTimeBottomSheet = false.obs;
  final pendingOrdersCount = 0.obs;
  final isStoreOpen = false.obs;
  //order management
  final ordersList = <Order>[].obs;
  final localOrdersList = <Order>[].obs;
  final isLoadingOrders = false.obs;
  String? bearerKey;
  final orderStats = {
    'accepted': 0,
    'declined': 0,
    'pending': 0,
    'pickup': 0,
    'delivery': 0,
    'totalOrders': 0,
  }.obs;

  final syncRotationController = Rx<AnimationController?>(null);
  final syncRotationAnimation = Rx<Animation<double>?>(null);



  GlobalKey getCategoryKey(int index) {
    // grow the list with new GlobalKeys until index exists
    while (categoryKeys.length <= index) {
      categoryKeys.add(GlobalKey());
    }
    return categoryKeys[index];
  }

  final dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    _setOrientation();
    _initializeSharedPreferences();
    _setupScrollListener();
    _initializeSocketConnection();
    _listenToNewOrders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupLandscapeScrollListener();
    });
  }

  @override
  void onClose() {
    noteController.dispose();
    searchController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    regionController.dispose();
    mainScrollController.dispose();
    sidebarScrollController.dispose();
    landscapeCategoryScrollController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    addressFocusNode.dispose();
    _socketService.disconnect();
    showOrderOverlay.value = false;
    super.onClose();
  }

  Future<void> _loadNextInvoiceNumber() async {
    if (storeId == null) return;

    final orderCount = await dbHelper.getDataCount(storeId!);
    invoiceNumber.value = (orderCount['orders'] ?? 0) + 1;
  }

  Future<void> _loadPendingOrdersCount() async {
    if (storeId == null) return;

    try {
      List<Map<String, dynamic>> unsyncedOrders = await dbHelper.getUnsyncedOrders(storeId!);
      pendingOrdersCount.value = unsyncedOrders.length;
      print('📊 Loaded ${pendingOrdersCount.value} pending orders');
    } catch (e) {
      print('❌ Error loading pending orders count: $e');
    }
  }

  Future<void> getDiscountPercentage() async {
    if (storeId == null || storeId!.isEmpty) return;

    try {
      List<GetDiscountPercentageResponseModel> discounts =
      await CallService().getDiscountPercentage(storeId!);

      if (discounts.isNotEmpty) {
        currentDiscounts = discounts;

        for (var discount in discounts) {
          if (discount.code?.toLowerCase().contains('delivery') == true) {
            deliveryDiscount.value = (discount.value ?? 0).toDouble();
            deliveryDiscountId = discount.id?.toString();
            print('✅ Delivery discount: ${deliveryDiscount.value}%, ID: $deliveryDiscountId');
          } else if (discount.code?.toLowerCase().contains('pickup') == true) {
            pickupDiscount.value = (discount.value ?? 0).toDouble();
            pickupDiscountId = discount.id?.toString();
            print('✅ Pickup discount: ${pickupDiscount.value}%, ID: $pickupDiscountId');
          }
        }
      }
    } catch (e) {
      print('❌ Error getting discount percentage: $e');
    }
  }

  void _listenToNewOrders() {
    if (storeId == null) return;

    oderSocketService.onNewOrder = (data) {
      if (data['store_id'] != null &&
          data['store_id'].toString() == storeId.toString()) {

        // ✅ Refresh AppController's order list (this auto-refreshes both OrderScreen AND POS)
        if (Get.isRegistered<AppController>()) {
          _refreshOrderScreenOrders();
        }

        // ✅ Refresh local orders only
        _loadLocalOrders();

        // Update pending count
        _loadPendingOrdersCount();
      }
    };
  }

  Future<void> _refreshOrderScreenOrders() async {
    try {
      if (bearerKey == null || storeId == null) return;

      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      final Map<String, dynamic> data = {
        "store_id": storeId,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (result.isNotEmpty && result.first.code == null) {
        app.appController.forceSetAllOrders(result);
        print('✅ OrderScreen orders refreshed from POS socket');
      }
    } catch (e) {
      print('❌ Error refreshing OrderScreen orders: $e');
    }
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _setupScrollListener() {
    mainScrollController.addListener(_onMainScroll);
  }

  void _onMainScroll() {
    if (isScrollingProgrammatically.value || isSearching.value) return;

    for (int i = 0; i < categoryKeys.length; i++) {
      final RenderBox? renderBox =
          categoryKeys[i].currentContext?.findRenderObject() as RenderBox?;

      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final height = renderBox.size.height;

        if (position.dy <= 150 && position.dy + height > 150) {
          if (selectedCategoryIndex.value != i) {
            selectedCategoryIndex.value = i;
            _scrollSidebarToCategory(i);
            break;
          }
        }
      }
    }
  }

  void _scrollSidebarToCategory(int index) {
    double itemHeight = 80.0;
    double targetPosition = index * itemHeight;

    sidebarScrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void scrollToCategory(int index) {
    isScrollingProgrammatically.value = true;
    selectedCategoryIndex.value = index;

    final RenderBox? renderBox =
        categoryKeys[index].currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final currentScroll = mainScrollController.position.pixels;

      mainScrollController.animateTo(
        currentScroll + position.dy + 160,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        isScrollingProgrammatically.value = false;
      });
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      bearerKey = sharedPreferences!.getString(valueShared_BEARER_KEY);

      await getProductCategory();
      await getDiscountPercentage();
      await _loadNextInvoiceNumber();
      await _loadPendingOrdersCount();
      await getStoreTiming();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      isLoading.value = false;
    }
  }

  Future<void> _initializeSocketConnection() async {
    try {
      await _socketService.connect();
      await Future.delayed(const Duration(milliseconds: 2000));

      if (storeId != null) {
        _listenToStoreStatus();
      }
    } catch (e) {
      print('❌ Error initializing socket: $e');
    }
  }

  void _listenToStoreStatus() {
    if (storeId == null) return;

    _socketService.listenToStoreStatus(storeId!);

    _socketService.storeStatusStream.listen((data) {
      isStoreOpen.value = data['is_open'] ?? false;

      _parseStoreOpeningTime(data['today_hours']);
      _generateSofortTimeSlots();
        });
  }

  void _parseStoreOpeningTime(List<dynamic>? todayHours) {
    if (todayHours == null || todayHours.isEmpty) return;

    String? openTime = todayHours[0]['open_time'];
    if (openTime != null) {
      List<String> parts = openTime.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      storeOpeningTime.value = DateTime(2023, 1, 1, hour, minute);
      print('🕐 Store opening time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    }
  }

  void _generateSofortTimeSlots() {
    sofortTimeSlots.clear();

    if (storeOpeningTime.value == null) {
      print('⚠️ Store opening time not available');
      return;
    }
    if (!isStoreOpen.value) {
      print('🚫 Store is currently CLOSED - No sofort slots generated for today');
      print('ℹ️ Store opens at: ${storeOpeningTime.value!.hour.toString().padLeft(2, '0')}:${storeOpeningTime.value!.minute.toString().padLeft(2, '0')}');
      return;
    }
    // ✅ Get current Germany time
    DateTime nowUtc = DateTime.now().toUtc();
    bool isDST = _isDaylightSavingTime(nowUtc);
    int germanyOffset = isDST ? 2 : 1;
    DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));

    int currentHour = nowGermany.hour;
    int currentMinute = nowGermany.minute;
    int currentTotalMinutes = (currentHour * 60) + currentMinute;

    print("⏰ Current Germany time: ${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}");

    DateTime startTime;
    int intervalMinutes = 15;
    int minimumPrepTime; // This will be used to calculate minimum available slot

    if (selectedOrderType.value == 'Lieferzeit') {
      // Delivery: delivery time + 15 min
      int deliveryMinutes = selectedPostcode.value?.deliveryTime ?? 60;
      startTime = storeOpeningTime.value!.add(Duration(minutes: deliveryMinutes + 15));
      minimumPrepTime = deliveryMinutes + 15;
    } else {
      // Pickup: 30 min
      startTime = storeOpeningTime.value!.add(const Duration(minutes: 30));
      minimumPrepTime = 30;
    }

    // ✅ Calculate minimum available time based on current Germany time
    DateTime minAvailableTime = nowGermany.add(Duration(minutes: minimumPrepTime));

    // ✅ Round up to next 15-minute interval
    int minAvailableMinutes = (minAvailableTime.hour * 60) + minAvailableTime.minute;
    int remainder = minAvailableMinutes % 15;
    if (remainder != 0) {
      minAvailableMinutes += (15 - remainder);
    }

    print("🎯 Minimum available time: ${minAvailableMinutes ~/ 60}:${(minAvailableMinutes % 60).toString().padLeft(2, '0')}");

    // Generate slots till 10 PM
    DateTime endTime = DateTime(2023, 1, 1, 22, 0);
    DateTime currentSlot = startTime;

    while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
      int slotTotalMinutes = (currentSlot.hour * 60) + currentSlot.minute;

      // ✅ Only add slot if it's after minimum available time
      if (slotTotalMinutes >= minAvailableMinutes) {
        String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
        sofortTimeSlots.add({'time24': time24});
        print("✅ Added slot: $time24 (slot: $slotTotalMinutes >= min: $minAvailableMinutes)");
      } else {
        print("❌ Skipped slot: ${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')} (too early)");
      }

      currentSlot = currentSlot.add(Duration(minutes: intervalMinutes));
    }

    print('✅ Generated ${sofortTimeSlots.length} available sofort time slots');
  }

  Future<void> getStoreTiming() async {
    if (storeId == null) {
      print('❌ Store ID not available');
      return;
    }

    try {
      List<GetStoreTimingResponseModel> storeTiming =
      await CallService().getStoreTiming(storeId!);

      storeTimingList = storeTiming;
      print('✅ Store timing loaded: ${storeTiming.length} entries');

      // Save to database
      await _saveStoreTimingToDb(storeTiming);

    } catch (e) {
      print('❌ Error getting Store Timing: $e');
    }
  }

  Future<void> _saveStoreTimingToDb(List<GetStoreTimingResponseModel> timings) async {
    final db = await dbHelper.database;

    for (var timing in timings) {
      await db.insert(
        'store_timings',
        {
          'id': timing.id.toString(),
          'day_of_week': timing.dayOfWeek,
          'opening_time': timing.openingTime,
          'closing_time': timing.closingTime,
          'store_id': timing.storeId.toString(),
          'name': timing.name,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    print('✅ Store timings saved to database');
  }

  Future<List<Map<String, String>>> generateVorbestellenTimeSlots(DateTime selectedDate) async {
    List<Map<String, String>> slots = [];

    // ✅ Get current Germany time
    DateTime nowUtc = DateTime.now().toUtc();
    bool isDST = _isDaylightSavingTime(nowUtc);
    int germanyOffset = isDST ? 2 : 1;
    DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));

    bool isToday = selectedDate.day == nowGermany.day &&
        selectedDate.month == nowGermany.month &&
        selectedDate.year == nowGermany.year;

    // Check if selected date is Tuesday to Friday
    int dayOfWeek = selectedDate.weekday; // Monday=1, Sunday=7
    bool isWebSocketDay = (dayOfWeek >= 2 && dayOfWeek <= 5); // Tue-Fri

    String? openTime;
    String? closeTime;

    if (isWebSocketDay && storeOpeningTime.value != null) {
      // ✅ Use WebSocket data for Tuesday-Friday
      openTime = '${storeOpeningTime.value!.hour.toString().padLeft(2, '0')}:${storeOpeningTime.value!.minute.toString().padLeft(2, '0')}';
      closeTime = '22:00'; // Default closing time
      print('📡 Using WebSocket timing for ${_getDayName(dayOfWeek)}');
    } else {
      // ✅ Use API data for other days
      GetStoreTimingResponseModel? dayTiming = storeTimingList.firstWhere(
            (timing) => timing.dayOfWeek == dayOfWeek,
        orElse: () => GetStoreTimingResponseModel(),
      );

      if (dayTiming.openingTime != null && dayTiming.closingTime != null) {
        openTime = dayTiming.openingTime;
        closeTime = dayTiming.closingTime;
        print('📅 Using API timing for ${_getDayName(dayOfWeek)}: $openTime - $closeTime');
      } else {
        print('⚠️ No timing data available for ${_getDayName(dayOfWeek)}');
        return slots;
      }
    }

    if (openTime == null || closeTime == null) {
      return slots;
    }

    // Parse times
    List<String> openParts = openTime.split(':');
    List<String> closeParts = closeTime.split(':');

    int openHour = int.parse(openParts[0]);
    int openMinute = int.parse(openParts[1]);
    int closeHour = int.parse(closeParts[0]);
    int closeMinute = int.parse(closeParts[1]);

    DateTime currentSlot;
    int intervalMinutes = 15;
    int minimumPrepTime;

    if (selectedOrderType.value == 'Lieferzeit') {
      int deliveryMinutes = selectedPostcode.value?.deliveryTime ?? 60;
      minimumPrepTime = deliveryMinutes + 15;
      currentSlot = DateTime(2023, 1, 1, openHour, openMinute).add(Duration(minutes: minimumPrepTime));
    } else {
      minimumPrepTime = 30;
      currentSlot = DateTime(2023, 1, 1, openHour, openMinute).add(Duration(minutes: minimumPrepTime));
    }

    DateTime endTime = DateTime(2023, 1, 1, closeHour, closeMinute);

    // ❌ REMOVE: isToday condition for vorbestellen - show all slots
    // ✅ For Vorbestellen, always show full day slots regardless of current time

    while (currentSlot.isBefore(endTime) || currentSlot.isAtSameMomentAs(endTime)) {
      String time24 = '${currentSlot.hour.toString().padLeft(2, '0')}:${currentSlot.minute.toString().padLeft(2, '0')}';
      slots.add({'time24': time24});

      currentSlot = currentSlot.add(Duration(minutes: intervalMinutes));
    }

    print('✅ Generated ${slots.length} slots for ${_getDayName(dayOfWeek)} (Vorbestellen - all day slots)');
    return slots;
  }

  String _getDayName(int dayOfWeek) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }


  void showPostcodeSelector(BuildContext context) {
    if (postcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading postcodes...'), backgroundColor: Colors.orange),
      );
      return;
    }

    showPostcodeDialog.value = true;
  }

  void selectPostcode(GetStorePostCodesResponseModel selectedPostcodeItem) {
    selectedPostcode.value = selectedPostcodeItem;
    regionController.text = selectedPostcodeItem.postcode ?? '';
    showPostcodeDialog.value = false;

    // Regenerate sofort time slots based on new delivery time
    _generateSofortTimeSlots();
  }

  // Update setOrderType method:
  void setOrderType(String type) {
    selectedOrderType.value = type;

    if (type == 'Lieferzeit' && postcode.isNotEmpty) {
      // Auto-select first postcode for delivery
      selectedPostcode.value = postcode.first;
      regionController.text = postcode.first.postcode ?? '';
    } else if (type == 'Abholzeit') {
      // Clear postcode for pickup
      selectedPostcode.value = null;
      regionController.text = '';
    }

    _generateSofortTimeSlots();
  }

  void filterProducts(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Reset to show all products
      filteredProducts.clear();
    } else {
      // Filter products by name or ID
      filteredProducts.value = productList.where((product) {
        final searchLower = query.toLowerCase();
        final nameLower = (product.name ?? '').toLowerCase();
        final idMatch = product.id.toString().contains(query);

        return (nameLower.contains(searchLower) || idMatch) &&
            (product.isActive ?? false);
      }).toList();
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    isSearching.value = value.isNotEmpty;
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  void addToCart(GetStoreProducts product) {
    int existingIndex =
        cartItems.indexWhere((item) => item['name'] == product.name);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
      cartItems.add({
        'name': product.name ?? '',
        'extras': '',
        'size': '',
        'quantity': 1,
        'price': double.tryParse(product.price?.toString() ?? '0') ?? 0.0,
      });
    }
    cartItems.refresh();
  }

  void addToCartWithVariant() {
    if (selectedProduct.value == null || selectedVariant.value == null) return;

    double basePrice = double.tryParse(selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variantPrice = (selectedVariant.value!.price ?? 0).toDouble();

    double toppingPrice = 0.0;
    List<String> toppingDetails = [];
    List<Map<String, dynamic>> toppingDataList = [];  // ✅ This line should exist

    print('🔍 Checking toppings for variant ${selectedVariant.value!.id}');
    print('🔍 Selected topping IDs: ${selectedToppingsMap[selectedVariant.value!.id]}');

    if (selectedToppingsMap.containsKey(selectedVariant.value!.id)) {
      var selectedToppingIds = selectedToppingsMap[selectedVariant.value!.id]!;

      print('🔍 Found ${selectedToppingIds.length} selected toppings');
      // List<Map<String, dynamic>> toppingDataList = [];  // ✅ REMOVE THIS LINE IF IT EXISTS HERE

      selectedVariant.value!.enrichedToppingGroups?.forEach((group) {
        group.toppings?.forEach((topping) {
          if (selectedToppingIds.contains(topping.id)) {
            toppingPrice += topping.price ?? 0.0;
            toppingDetails.add('${topping.name} [${"currency".tr}${(topping.price ?? 0.0).toStringAsFixed(2)}]');

            // ✅ ADD DEBUG PRINT HERE
            print('🍕 Adding topping to data: ${topping.name} with ID: ${topping.id}');

            // ✅ Store actual topping ID (not composite key)
            toppingDataList.add({
              'topping_id': topping.id,  // ✅ Actual topping ID from API
              'name': topping.name,
              'price': topping.price ?? 0.0,
              'quantity': 1,
            });

            print('✅ Added topping: ${topping.name} with ID: ${topping.id}');
          }
        });
      });
    }

    print('✅ Total toppings added: ${toppingDetails.length}');
    print('✅ Total toppingDataList: ${toppingDataList.length}'); // ✅ ADD THIS

    double totalPrice = basePrice + variantPrice + toppingPrice;
    String variantName = selectedVariant.value!.name ?? '';
    String itemKey = '${selectedProduct.value!.name}_${variantName}_${toppingDetails.join(',')}';

    int existingIndex = cartItems.indexWhere((item) => item['key'] == itemKey);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
      // ✅ ADD DEBUG BEFORE ADDING TO CART
      print('🛒 Adding to cart with ${toppingDataList.length} toppings');

      cartItems.add({
        'key': itemKey,
        'name': selectedProduct.value!.name ?? '',
        'extras': toppingDetails.join('\n'),
        'size': variantName,
        'quantity': 1,
        'price': totalPrice,
        'variant_id': selectedVariant.value!.id,
        'product_id': selectedProduct.value!.id,
        'topping_details': toppingDetails,
        'topping_data': toppingDataList,  // ✅ Make sure this is the list, not empty
        'item_note': '',
      });

      // ✅ VERIFY AFTER ADDING
      print('✅ Cart item added. Verifying topping_data: ${cartItems.last['topping_data']}');
    }

    print('✅ Cart item added with ${toppingDetails.length} toppings');

    cartItems.refresh();
    showVariantDialog.value = false;
    selectedProduct.value = null;
    selectedVariant.value = null;
    selectedToppingsMap.clear();
    expandedVariantId.value = null;
  }

  // Remove cart item
  void removeCartItem(int index) {
    cartItems.removeAt(index);
    cartItems.refresh();
  }

// Show item note dialog
  void showItemNoteDialog(BuildContext context, int itemIndex) {
    TextEditingController itemNoteController = TextEditingController();
    itemNoteController.text = cartItems[itemIndex]['item_note'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Item Note',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xff0B1928),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: itemNoteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter note for this item...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xffE31E24)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          cartItems[itemIndex]['item_note'] = itemNoteController.text;
                          cartItems.refresh();
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Item note added successfully',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Color(0xff00B10E),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffE31E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Save Note',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void setupLandscapeScrollListener() {
    landscapeProductPositionsListener.itemPositions.addListener(() {
      if (isAutoScrolling.value) return;

      final positions = landscapeProductPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      // ✅ Filter positions and check if result is empty before reduce
      final visiblePositions = positions
          .where((position) => position.itemLeadingEdge >= -0.3)
          .toList();

      // ✅ Check if we have any visible positions after filtering
      if (visiblePositions.isEmpty) return;

      final firstVisible = visiblePositions
          .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);

      int visibleIndex = firstVisible.index;

      // Map visible index to category index
      if (visibleIndex < visibleCategories.length) {
        int categoryIndex = visibleCategories[visibleIndex];

        if (categoryIndex != selectedCategoryIndex.value) {
          selectedCategoryIndex.value = categoryIndex;
          scrollCategoryToIndex(categoryIndex);
        }
      }
    });
  }

  void selectCategory(int index) async {
    if (isAutoScrolling.value) return;
    if (index >= productCategoryList.length) return;

    selectedCategoryIndex.value = index;
    isAutoScrolling.value = true;

    print('🎯 Selecting category $index');

    // Ensure category is visible
    if (!visibleCategories.contains(index)) {
      // Load all categories up to this index plus buffer
      for (int i = 0; i <= (index + 5).clamp(0, productCategoryList.length - 1); i++) {
        if (!visibleCategories.contains(i)) {
          visibleCategories.add(i);
        }
      }
      visibleCategories.sort();
      visibleCategories.refresh();

      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Find the position in visible categories list
    int visibleIndex = visibleCategories.indexOf(index);

    if (visibleIndex != -1) {
      try {
        await landscapeProductScrollController.scrollTo(
          index: visibleIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.05, // Small offset from top
        );

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        print('Scroll error: $e');
      }
    }

    isAutoScrolling.value = false;
  }

  void scrollCategoryToIndex(int index) {
    if (!landscapeCategoryScrollController.hasClients) return;

    double targetPosition = index * 85.0;
    double maxScroll =
        landscapeCategoryScrollController.position.maxScrollExtent;

    if (targetPosition > maxScroll) {
      targetPosition = maxScroll;
    }

    landscapeCategoryScrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void initializeVisibleCategories() {
    visibleCategories.clear();
    lastScrollPosition.value = 0.0;

    // Load all categories at once for ScrollablePositionedList
    // This is efficient because it only renders visible items
    for (int i = 0; i < productCategoryList.length; i++) {
      visibleCategories.add(i);
    }

    visibleCategories.refresh();

    print('📦 Initialized with all ${visibleCategories.length} categories');
  }

  void addToCartPortrait(Product product) {
    if (cart.containsKey(product.name)) {
      cart[product.name]!.quantity++;
    } else {
      cart[product.name] = CartItem(product: product, quantity: 1);
    }
    calculateTotal();
  }

  void removeFromCartPortrait(Product product) {
    if (cart.containsKey(product.name)) {
      if (cart[product.name]!.quantity > 1) {
        cart[product.name]!.quantity--;
      } else {
        cart.remove(product.name);
      }
      calculateTotal();
    }
  }

  void showProductVariantDialog(GetStoreProducts product) async {
    selectedProduct.value = product;
    selectedVariant.value = null;
    selectedToppings.clear();
    expandedVariantId.value = null;
    selectedToppingsMap.clear();
    // Load variants from database if not already loaded
    if (product.variants == null || product.variants!.isEmpty) {
      product.variants = await dbHelper.getProductVariants(product.id.toString());

      // Load topping groups for each variant
      for (var variant in product.variants!) {
        if (variant.id != null) {
          variant.enrichedToppingGroups = await dbHelper.getVariantToppingGroups(variant.id.toString());
          print('🍕 Loaded ${variant.enrichedToppingGroups?.length ?? 0} topping groups for variant ${variant.id}');
        }
      }
    }

    // Only show dialog if product has variants
    if (product.variants != null && product.variants!.isNotEmpty) {
      showVariantDialog.value = true;
    } else {
      // No variants, add directly to cart
      addToCart(product);
    }
  }

  void selectVariant(Variants variant) {
    selectedVariant.value = variant;
    // Automatically expand if variant has toppings
    if (variant.enrichedToppingGroups != null && variant.enrichedToppingGroups!.isNotEmpty) {
      expandedVariantId.value = variant.id;
    }
  }

  void toggleTopping(String topping) {
    if (selectedToppings.contains(topping)) {
      selectedToppings.remove(topping);
    } else {
      selectedToppings.add(topping);
    }
  }

  void toggleVariantExpansion(int variantId) {
    if (expandedVariantId.value == variantId) {
      expandedVariantId.value = null;
    } else {
      expandedVariantId.value = variantId;
    }
  }

  void toggleVariantTopping(int variantId, int toppingId) {
    if (!selectedToppingsMap.containsKey(variantId)) {
      selectedToppingsMap[variantId] = [];
    }

    if (selectedToppingsMap[variantId]!.contains(toppingId)) {
      selectedToppingsMap[variantId]!.remove(toppingId);
    } else {
      selectedToppingsMap[variantId]!.add(toppingId);
    }
    selectedToppingsMap.refresh();
  }
  // Landscape Mode - Increment Quantity
  void incrementQuantity(int index) {
    cartItems[index]['quantity']++;
    cartItems.refresh();
  }

  // Landscape Mode - Decrement Quantity
  void decrementQuantity(int index) {
    if (cartItems[index]['quantity'] > 1) {
      cartItems[index]['quantity']--;
      cartItems.refresh();
    } else {
      cartItems.removeAt(index);
      cartItems.refresh();
    }
  }

  // Landscape Mode - Calculations
  double calculateSubtotal() {
    double subtotal = 0;
    for (var item in cartItems) {
      subtotal += item['price'] * item['quantity'];
    }
    return subtotal;
  }

  double calculateDiscount() {
    double subtotal = calculateSubtotal();
    double discountPercent = 0.0;

    // Apply discount based on selected order type
    if (selectedOrderType.value == 'Lieferzeit') {
      discountPercent = deliveryDiscount.value;
    } else if (selectedOrderType.value == 'Abholzeit') {
      discountPercent = pickupDiscount.value;
    }

    return subtotal * (discountPercent / 100);
  }

  double calculateGrandTotal() {
    return calculateSubtotal() - calculateDiscount();
  }

  // Portrait Mode - Calculate Total
  void calculateTotal() {
    totalPrice.value = 0.0;
    totalItems.value = 0;
    cart.forEach((key, cartItem) {
      totalPrice.value += cartItem.product.price * cartItem.quantity;
      totalItems.value += cartItem.quantity;
    });
  }

  int getProductQuantity(Product product) {
    return cart[product.name]?.quantity ?? 0;
  }

  bool isProductSelected(Product product) {
    return cart.containsKey(product.name);
  }

  // Portrait Mode - Get Filtered Categories
  List<CategoryData> getFilteredCategories() {
    if (searchQuery.value.isEmpty) {
      return categories;
    }

    List<CategoryData> filtered = [];
    for (var category in categories) {
      List<Product> filteredProducts = category.products
          .where((product) => product.name
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()))
          .toList();

      if (filteredProducts.isNotEmpty) {
        filtered.add(CategoryData(
          name: category.name,
          image: category.image,
          products: filteredProducts,
          id: category.id,
          imageUrl: category.imageUrl,
        ));
      }
    }
    return filtered;
  }

  void saveNote(String note) {
    orderNote.value = note;
    Get.back();

    if (Get.context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.context != null && Get.context!.mounted) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            const SnackBar(
              content: Text(
                'Note added successfully',
                style: TextStyle(
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Color(0xff00B10E),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      if (Get.context != null && Get.context!.mounted) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(
            content: Text(
              'Please add items to cart',
              style: TextStyle(
                fontFamily: 'Mulish',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Color(0xffE31E24),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        var product = productList.firstWhere(
              (p) => p.name == item['name'],
          orElse: () => GetStoreProducts(id: 0),
        );

        // ✅ FIX: Check both 'topping_data' AND 'toppings'
        List<Map<String, dynamic>>? toppings;

        // First check topping_data
        if (item['topping_data'] != null && item['topping_data'] is List) {
          toppings = List<Map<String, dynamic>>.from(item['topping_data']);
          print('✅ Found topping_data with ${toppings.length} items');
        }
        // Fallback to check 'toppings' key
        else if (item['toppings'] != null && item['toppings'] is List) {
          toppings = List<Map<String, dynamic>>.from(item['toppings']);
          print('✅ Found toppings with ${toppings.length} items');
        }

        // ✅ DEBUG: Print entire cart item to see structure
        print('🔍 CART ITEM STRUCTURE: ${item.keys.toList()}');
        print('🔍 Cart item name: ${item['name']}');
        print('🔍 Has topping_data? ${item['topping_data'] != null}');
        print('🔍 Has toppings? ${item['toppings'] != null}');
        if (item['topping_data'] != null) {
          print('🔍 topping_data content: ${item['topping_data']}');
        }
        if (item['toppings'] != null) {
          print('🔍 toppings content: ${item['toppings']}');
        }
        return {
          'product_id': product.id ?? 0,
          'quantity': item['quantity'],
          'price': item['price'],
          'variant_id': item['variant_id'],
          'note': item['item_note'] ?? '',
          'toppings': toppings,
        };
      }).toList();

      String? discountId;
      if (selectedOrderType.value == 'Lieferzeit') {
        discountId = deliveryDiscountId;
      } else if (selectedOrderType.value == 'Abholzeit') {
        discountId = pickupDiscountId;
      }

      // ✅ NEW: Get Germany time instead of UTC
      final germanyTime = _getGermanyTime();

      // Calculate delivery time based on selection
      String? deliveryTime;
      if (selectedDate.value != null && selectedTimeSlot.value != 'sofort') {
        // Vorbestellen - use selected date & time
        String timeString = selectedTimeSlot.value; // "15:00"
        List<String> timeParts = timeString.split(':');
        DateTime deliveryDateTime = DateTime(
          selectedDate.value!.year,
          selectedDate.value!.month,
          selectedDate.value!.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        deliveryTime = deliveryDateTime.toIso8601String();
      } else if (selectedTimeSlot.value == 'sofort') {
        // Sofort - use current time + delivery time from postcode
        int deliveryMinutes = selectedPostcode.value?.deliveryTime ?? 30;
        DateTime sofortTime = germanyTime.add(Duration(minutes: deliveryMinutes));
        deliveryTime = sofortTime.toIso8601String();
      }

      int orderId = await dbHelper.saveOrder(
        storeId: storeId!,
        orderType: selectedOrderType.value == 'Lieferzeit' ? '1' : '2',
        note: orderNote.value.isEmpty ? null : orderNote.value,
        customerName: customerDetails['name'] ?? '',
        phone: customerDetails['phone'] ?? '',
        email: customerDetails['email'] ?? '',
        address: customerDetails['address'] ?? '',
        zip: customerDetails['region'] ?? '',
        items: orderItems,
        amount: calculateGrandTotal(),
        discountId: discountId,
        createdAt: germanyTime,
        deliveryTime: deliveryTime,
      );
      pendingOrdersCount.value++;
      print('📈 Pending orders count increased to: ${pendingOrdersCount.value}');

      print('✅ Order placed with ID: $orderId at Germany time: $germanyTime');
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order placed successfully! Order #$orderId',
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xff0C831F),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      invoiceNumber.value++;

      cartItems.clear();
      orderNote.value = '';
      noteController.clear();
      showCustomerDetails.value = false;
      isCartExpanded.value = true;
      customerDetails.clear();
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      regionController.clear();

    } catch (e) {
      print('❌ Error placing order: $e');
    }
  }

  void decreasePendingOrdersCount() {
    if (pendingOrdersCount.value > 0) {
      pendingOrdersCount.value--;
      print('📉 Pending orders count decreased to: ${pendingOrdersCount.value}');
    }
  }
  Future<void> refreshPendingOrdersCount() async {
    await _loadPendingOrdersCount();
  }

  DateTime _getGermanyTime() {
    DateTime utcNow = DateTime.now().toUtc();

    // Check if DST is active in Germany
    bool isDST = _isDaylightSavingTime(utcNow);
    int germanyOffset = isDST ? 2 : 1; // UTC+2 in summer, UTC+1 in winter

    DateTime germanyTime = utcNow.add(Duration(hours: germanyOffset));

    print('🕐 UTC: $utcNow');
    print('🇩🇪 Germany time: $germanyTime (DST: $isDST, Offset: +$germanyOffset)');

    return germanyTime;
  }

  bool _isDaylightSavingTime(DateTime dateTime) {
    int year = dateTime.year;

    // Find last Sunday of March
    DateTime marchEnd = DateTime.utc(year, 3, 31);
    while (marchEnd.weekday != DateTime.sunday) {
      marchEnd = marchEnd.subtract(const Duration(days: 1));
    }

    // Find last Sunday of October
    DateTime octoberEnd = DateTime.utc(year, 10, 31);
    while (octoberEnd.weekday != DateTime.sunday) {
      octoberEnd = octoberEnd.subtract(const Duration(days: 1));
    }

    // DST starts at 2:00 AM on last Sunday of March
    DateTime dstStart = DateTime.utc(year, marchEnd.month, marchEnd.day, 2, 0);

    // DST ends at 3:00 AM on last Sunday of October
    DateTime dstEnd = DateTime.utc(year, octoberEnd.month, octoberEnd.day, 3, 0);

    return dateTime.isAfter(dstStart) && dateTime.isBefore(dstEnd);
  }


  DateTime getCurrentGermanyDate() {
    DateTime nowUtc = DateTime.now().toUtc();
    bool isDST = _isDaylightSavingTime(nowUtc);
    int germanyOffset = isDST ? 2 : 1;
    DateTime nowGermany = nowUtc.add(Duration(hours: germanyOffset));
    return DateTime(nowGermany.year, nowGermany.month, nowGermany.day);
  }

  bool isDateInPast(DateTime date) {
    DateTime currentGermanyDate = getCurrentGermanyDate();
    return date.isBefore(currentGermanyDate) || date.isAtSameMomentAs(currentGermanyDate);
  }
  void onWeiterPressed() {
    if (!showCustomerDetails.value) {
      isCartExpanded.value = false;
      showCustomerDetails.value = true;
      isCustomerFormVisible.value = true;
    } else if (isCustomerFormVisible.value) {
      customerDetails.value = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(), // ✅ Single address
        'region': regionController.text.trim(), // ✅ REMOVE THIS LINE
      };
      isCustomerFormVisible.value = false;
    } else {
      placeOrder();
      showCustomerDetails.value = false;
      isCartExpanded.value = true;
      customerDetails.clear();
      nameController.clear();
      phoneController.clear();
      emailController.clear();
      addressController.clear();
      regionController.clear(); // ✅ REMOVE THIS LINE
    }
  }

  void onAddCustomerPressed() {
    isCartExpanded.value = false;
    showCustomerDetails.value = true;
    isCustomerFormVisible.value = true;
  }

  // Toggle Customer Details
  void toggleCustomerDetails() {
    showCustomerDetails.value = false;
    isCartExpanded.value = true;
  }

  // Edit Customer Details
  void editCustomerDetails() {
    isCustomerFormVisible.value = true;
    nameController.text = customerDetails['name'] ?? '';
    phoneController.text = customerDetails['phone'] ?? '';
    addressController.text = customerDetails['address'] ?? '';
    emailController.text = customerDetails['email'] ?? '';
    regionController.text = customerDetails['region'] ?? '';
  }

  List<String> getTimeSlots() {
    List<String> slots = [];
    for (int hour = 15; hour <= 23; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  void openTimeBottomSheet() {
    showTimeBottomSheet.value = true;
  }

  void closeTimeBottomSheet() {
    showTimeBottomSheet.value = false;
  }

  void selectTimeSlot(String time) {
    selectedTimeSlot.value = time;
    closeTimeBottomSheet();
  }

  void selectHeute() {
    isHeuteSelected.value = true;
    isVorbestellenSelected.value = false;
    selectedDate.value = null;
    showCalendar.value = false;
    showTimeSelector.value = false;

    // ✅ ADD THIS - Regenerate slots to check if store is open
    _generateSofortTimeSlots();

    // ✅ OPTIONAL: Show message if store is closed
    if (!isStoreOpen.value && Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text(
            'Store is currently closed. Please select "Vorbestellen" to schedule for later.',
            style: TextStyle(
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xffE31E24),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void selectVorbestellen() {
    isHeuteSelected.value = false;
    isVorbestellenSelected.value = true;
  }

  void openCalendar() {
    if (isVorbestellenSelected.value) {
      showCalendar.value = true;
    }
  }

  void closeCalendar() {
    showCalendar.value = false;
  }

  void showVorbestellenCalendar() {
    showCalendar.value = true;
  }

  void selectVorbestellenDate(DateTime date) async {
    selectedVorbestellenDate.value = date;

    // Generate time slots for selected date
    List<Map<String, String>> slots = await generateVorbestellenTimeSlots(date);
    sofortTimeSlots.clear();
    sofortTimeSlots.addAll(slots);

    showCalendar.value = false;
    showTimeSelector.value = true;

    print('📅 Selected date: ${date.day}/${date.month}/${date.year} with ${slots.length} slots');
  }

  void selectDate(DateTime date) async {
    selectedDate.value = date;
    selectedVorbestellenDate.value = date;

    // ✅ Generate slots for selected date
    List<Map<String, String>> slots = await generateVorbestellenTimeSlots(date);


    sofortTimeSlots.clear();
    sofortTimeSlots.addAll(slots);

    showTimeSelector.value = true;
    closeCalendar();

    print('📅 Selected: ${date.day}/${date.month}/${date.year} with ${slots.length} slots');
  }

  void openTimeSelector() {
    if (selectedDate.value != null) {
      openTimeBottomSheet();
    }
  }

  String getFormattedSelectedDateTime() {
    if (selectedDate.value != null) {
      String date = '${selectedDate.value!.day}.${selectedDate.value!.month}.${selectedDate.value!.year}';
      if (selectedTimeSlot.value != 'sofort') {
        return '$date - ${selectedTimeSlot.value}';
      }
      return date;
    }
    return 'Select Date';
  }

  Future<void> getProductCategory(
      {bool showLoader = true, bool forceRefresh = false}) async
  {
    if (sharedPreferences == null) {
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      isLoading.value = false;
      return;
    }

    if (!forceRefresh) {
      bool hasData = await dbHelper.hasStoredData(storeId!);
      if (hasData) {
        await _loadFromDatabase();
        return;
      }
    }

    if (showLoader) {
      isLoading.value = true;
      isRefreshing.value = true;
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
    }

    try {
      print('🌐 Fetching data from API...');
      List<GetProductCategoryList> categoryList = await CallService().getProductCategory(storeId!);

      List<GetStoreProducts> products = await CallService().getProducts(storeId!);

      await dbHelper.saveCategories(categoryList, storeId!);
      await dbHelper.saveProducts(products, storeId!);

      List<GetStorePostCodesResponseModel> postcodeList = await CallService().getPostCode(storeId!);
      await dbHelper.savePostcodes(postcodeList, storeId!);
      postcode.value = postcodeList;

      productCategoryList.value = categoryList;
      productList.value = products;

      if (categoryList.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      categories.value = categoryList
          .map((apiCategory) {
        return CategoryData.fromGetProductCategory(apiCategory, products);
      })
          .where((cat) => cat.products.isNotEmpty)
          .toList();

      categoryKeys = List.generate(categories.length, (index) => GlobalKey());

      if (productCategoryList.isNotEmpty && categories.isNotEmpty) {
        var firstCategory = productCategoryList[0];
        filteredProducts.value = productList
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      print('✅ Categories loaded and saved: ${categories.length}');

      // Initialize visible categories - load all for ScrollablePositionedList
      initializeVisibleCategories();

      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));

      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }

      isLoading.value = false;
      isRefreshing.value = false;

    } catch (e) {
      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }
      print('❌ Error getting Product Category: $e');
      isLoading.value = false;
      isRefreshing.value = false;

      print('📦 Attempting to load from database as fallback...');
      await _loadFromDatabase();
    }
  }

  Future<void> getPostCode({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      isLoading.value = false;
      return;
    }

    try {
      List<GetStorePostCodesResponseModel> postcodeValue = await CallService().getPostCode(storeId!);
      print('Postcode list length is ${postcodeValue.length}');

      if (showLoader) {
        Get.back();
      }
      postcode.value = postcodeValue;

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Postcode: $e');
    }
  }

  Future<void> _loadFromDatabase() async {
    try {
      print('📦 Loading from database...');

      List<GetProductCategoryList> categoryList =
      await dbHelper.getCategories(storeId!);
      List<GetStoreProducts> products = await dbHelper.getProducts(storeId!);

      List<GetStorePostCodesResponseModel> postcodeList = await dbHelper.getPostcodes(storeId!);
      postcode.value = postcodeList;

      if (categoryList.isEmpty || products.isEmpty) {
        print('⚠️ No data found in database');
        isLoading.value = false;
        return;
      }

      productCategoryList.value = categoryList;
      productList.value = products;

      if (categoryList.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      categories.value = categoryList
          .map((apiCategory) {
        return CategoryData.fromGetProductCategory(apiCategory, products);
      })
          .where((cat) => cat.products.isNotEmpty)
          .toList();

      categoryKeys = List.generate(categories.length, (index) => GlobalKey());

      if (categoryList.isNotEmpty && categories.isNotEmpty) {
        var firstCategory = categoryList[0];
        filteredProducts.value = products
            .where((p) =>
        p.categoryId == firstCategory.id && (p.isActive ?? false))
            .toList();
      }

      print('✅ Loaded ${categories.length} categories from database');

      // Initialize visible categories
      initializeVisibleCategories();

      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 300));

      isLoading.value = false;

    } catch (e) {
      print('❌ Error loading from database: $e');
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');
    visibleCategories.clear();
    await getProductCategory(showLoader: true, forceRefresh: true);

    if (!isLoading.value && categories.isNotEmpty) {
      if (Get.context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.context != null && Get.context!.mounted) {
            ScaffoldMessenger.of(Get.context!).showSnackBar(
              const SnackBar(
                content: Text(
                  'Data refreshed successfully',
                  style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Color(0xff00B10E),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    }
  }

  String getTrimmedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      return url.substring(0, queryIndex);
    }
    return url;
  }

  void showAddNoteDialog(BuildContext context) {
    noteController.text = orderNote.value; // Add .value
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Note',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xff0B1928),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter your note here...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xffE31E24)),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          orderNote.value =
                              noteController.text; // Changed from setState
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Note added successfully',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Color(0xff00B10E),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffE31E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Add Note',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(
                      Icons.power_settings_new,
                      color: Color(0xffE31E24),
                      size: 50,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xff0B1928),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Are you sure you want to logout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff797878),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Logged out successfully',
                                      style: TextStyle(
                                        fontFamily: 'Mulish',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: Color(0xff00B10E),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffE31E24),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ])
                  ])));
        });
  }

 /// order methods
  void toggleOrderOverlay() {
    showOrderOverlay.value = !showOrderOverlay.value;
  }

  void showOrdersOverlay() {
    showOrderOverlay.value = true;
    loadOrders(); // Load orders when overlay opens
  }

  void hideOrderOverlay() {
    showOrderOverlay.value = false;
  }

  /// Draft methods
  void toggleDraftPanel() {
    showDraftPanel.value = !showDraftPanel.value;
  }

  void saveAsDraft() {
    if (cartItems.isEmpty) return;

    // Capture confirmed details from map
    final confirmedDetails = Map<String, String>.from(customerDetails);

    // Also capture whatever is typed in form fields (even if form not submitted)
    final pendingForm = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'email': emailController.text.trim(),
      'address': addressController.text.trim(),
      'region': regionController.text.trim(),
    };

    // Merge: pending form values fill gaps, confirmed map takes priority
    final mergedDetails = <String, String>{};
    pendingForm.forEach((key, value) {
      if (value.isNotEmpty) mergedDetails[key] = value;
    });
    confirmedDetails.forEach((key, value) {
      if (value.isNotEmpty) mergedDetails[key] = value;
    });

    final draft = {
      'cartItems': cartItems.map((item) => Map<String, dynamic>.from(item)).toList(),
      'customerDetails': mergedDetails,
      'detailsConfirmed': confirmedDetails.isNotEmpty,
      'orderNote': orderNote.value,
      'selectedOrderType': selectedOrderType.value,
      'savedAt': DateTime.now().toIso8601String(),
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    drafts.add(draft);

    cartItems.clear();
    orderNote.value = '';
    noteController.clear();
    showCustomerDetails.value = false;
    isCartExpanded.value = true;
    customerDetails.clear();
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    regionController.clear();
  }

  void loadDraft(int index) {
    final draft = drafts[index];

    cartItems.clear();
    customerDetails.clear();

    final List<Map<String, dynamic>> savedItems =
        List<Map<String, dynamic>>.from(
          (draft['cartItems'] as List).map((item) => Map<String, dynamic>.from(item)),
        );
    cartItems.addAll(savedItems);

    final Map<String, String> savedDetails =
        Map<String, String>.from(draft['customerDetails'] as Map);
    final bool detailsConfirmed = draft['detailsConfirmed'] as bool? ?? false;

    orderNote.value = draft['orderNote'] ?? '';
    noteController.text = orderNote.value;
    selectedOrderType.value = draft['selectedOrderType'] ?? 'Lieferzeit';

    if (savedDetails.isNotEmpty) {
      nameController.text = savedDetails['name'] ?? '';
      phoneController.text = savedDetails['phone'] ?? '';
      emailController.text = savedDetails['email'] ?? '';
      addressController.text = savedDetails['address'] ?? '';
      regionController.text = savedDetails['region'] ?? '';
      showCustomerDetails.value = true;

      if (detailsConfirmed) {
        // Details were confirmed — restore map and show display card
        customerDetails.addAll(savedDetails);
        isCustomerFormVisible.value = false;
      } else {
        // Details were only in form (not submitted) — show pre-filled form
        isCustomerFormVisible.value = true;
      }
    }

    drafts.removeAt(index);
    showDraftPanel.value = false;
  }

  void deleteDraft(int index) {
    drafts.removeAt(index);
  }

  Future<void> loadOrders() async {
    if (storeId == null) return;

    try {
      isLoadingOrders.value = true;

      // Load local orders from database
      await _loadLocalOrders();

      // Load server orders
      await _loadServerOrders();

      // Update stats
      _updateOrderStats();

    } catch (e) {
      print('❌ Error loading orders: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  Future<void> _loadLocalOrders() async {
    try {
      final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId!);
      List<Order> localOrders = [];

      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          Order order = await _convertDbOrderToOrderModel(orderDetails);
          localOrders.add(order);
        }
      }

      localOrdersList.value = localOrders;
      print('✅ Loaded ${localOrders.length} local orders');
    } catch (e) {
      print('❌ Error loading local orders: $e');
    }
  }

  Future<void> _loadServerOrders() async {
    try {
      // ✅ Add null check
      if (bearerKey == null || bearerKey!.isEmpty) {
        print('⚠️ Bearer key not available');
        return;
      }

      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      final Map<String, dynamic> data = {
        "store_id": storeId,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (result.isNotEmpty && result.first.code == null) {
        ordersList.value = result;
        print('✅ Loaded ${result.length} server orders');
      }
    } catch (e) {
      print('❌ Error loading server orders: $e');
    }
  }

  void _updateOrderStats() {
    int accepted = 0, declined = 0, pending = 0, pickup = 0, delivery = 0;

    final allOrders = [...localOrdersList, ...ordersList];

    for (var order in allOrders) {
      // Approval status
      if (order.approvalStatus == 2) {
        accepted++;
      } else if (order.approvalStatus == 3) declined++;
      else if (order.approvalStatus == 1) pending++;

      // Order type
      if (order.orderType == 2) {
        pickup++;
      } else if (order.orderType == 1) delivery++;
    }

    orderStats.value = {
      'accepted': accepted,
      'declined': declined,
      'pending': pending,
      'pickup': pickup,
      'delivery': delivery,
      'totalOrders': allOrders.length,
    };
  }

  Future<Order> _convertDbOrderToOrderModel(Map<String, dynamic> orderDetails) async {
    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;
    final itemsData = orderDetails['items'] as List<dynamic>;
    final paymentData = orderDetails['payment'] as Map<String, dynamic>?;

    ShippingAddress? shippingAddress;
    if (addressData != null) {
      shippingAddress = ShippingAddress(
        customer_name: addressData['customer_name'] as String?,
        phone: addressData['phone'] as String?,
        line1: addressData['line1'] as String?,
        city: addressData['city'] as String?,
        zip: addressData['zip'] as String?,
        country: addressData['country'] as String?,
        type: addressData['type'] as String?,
      );
    }

    GuestShippingJson? guestShippingJson;
    if (addressData != null) {
      guestShippingJson = GuestShippingJson(
        customerName: addressData['customer_name'] as String?,
        phone: addressData['phone'] as String?,
        line1: addressData['line1'] as String?,
        city: addressData['city'] as String?,
        zip: addressData['zip'] as String?,
        country: addressData['country'] as String?,
        type: addressData['type'] as String?,
      );
    }

    Payment? payment;
    if (paymentData != null) {
      payment = Payment(
        amount: (paymentData['amount'] as num?)?.toDouble(),
        paymentMethod: paymentData['payment_method'] as String?,
        status: paymentData['status'] as String?,
      );
    }

    List<OrderItem>? orderItems;
    if (itemsData.isNotEmpty) {
      final itemFutures = itemsData.map((item) async {
        String productName = 'Product';
        try {
          final productId = item['product_id'] as int?;
          if (productId != null) {
            final product = await DatabaseHelper().getProductById(productId.toString());
            if (product != null) {
              productName = product.name ?? 'Product';
            }
          }
        } catch (e) {
          print('Error getting product name: $e');
        }

        List<Topping>? toppings;
        if (item['toppings'] != null && item['toppings'] is List) {
          toppings = (item['toppings'] as List).map((t) {
            return Topping(
              toppingId: t['topping_id'] as int?,
              name: t['topping_name'] as String?,
              price: (t['topping_price'] as num?)?.toDouble(),
              quantity: t['topping_quantity'] as int?,
            );
          }).toList();
        }

        Variant? variant;
        if (item['variant'] != null && item['variant'] is Map) {
          final variantMap = item['variant'] as Map<String, dynamic>;
          variant = Variant(
            id: variantMap['id'] as int?,
            name: variantMap['name'] as String?,
            price: (variantMap['price'] as num?)?.toDouble(),
            itemCode: variantMap['item_code'] as String?,
            description: variantMap['description'] as String?,
          );
        }

        return OrderItem(
          id: item['id'] as int?,
          productId: item['product_id'] as int?,
          productName: productName,
          quantity: item['quantity'] as int?,
          unitPrice: (item['unit_price'] as num?)?.toDouble(),
          variantId: item['variant_id'] as int?,
          note: item['note'] as String? ?? '',
          variant: variant,
          toppings: toppings ?? [],
        );
      }).toList();

      orderItems = await Future.wait(itemFutures);
    }

    return Order(
      id: orderData['id'] as int?,
      orderNumber: orderData['id'] as int?,
      orderType: orderData['order_type'] as int?,
      orderStatus: orderData['order_status'] as int?,
      approvalStatus: orderData['approval_status'] as int?,
      note: orderData['note'] as String? ?? '',
      deliveryTime: orderData['delivery_time'] as String?,
      storeId: orderData['store_id'] != null ? int.tryParse(orderData['store_id'].toString()) : null,
      isActive: orderData['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(orderData['created_at'] as int, isUtc: true).toIso8601String(),
      shipping_address: shippingAddress,
      guestShippingJson: guestShippingJson,
      payment: payment,
      items: orderItems ?? [],
      isLocalOrder: true,
    );
  }

  Future<void> syncLocalOrders() async {
    try {
      final unsyncedOrders = await DatabaseHelper().getUnsyncedOrders(storeId!);

      if (unsyncedOrders.isEmpty) {
        print('ℹ️ No orders to sync');
        return;
      }

      List<int> localOrderIds = unsyncedOrders.map((o) => o['id'] as int).toList();
      List<Map<String, dynamic>> ordersToSync = [];

      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await DatabaseHelper().getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          ordersToSync.add(await _buildSyncOrderMap(orderDetails));
        }
      }

      SyncLocalOrder model = await CallService().syncLocalOrder(ordersToSync);

      if (model.status == 'ok' && model.syncedOrderIds != null) {
        // ✅ Mark orders as synced
        for (int localOrderId in localOrderIds) {
          await DatabaseHelper().markOrderAsSynced(localOrderId);
          decreasePendingOrdersCount();
        }

        // ✅ First load local orders (will be empty now since synced)
        await _loadLocalOrders();
        await _refreshAppControllerOrders();
        // // ✅ Then refresh AppController with latest server orders
        // if (Get.isRegistered<AppController>()) {
        //
        // }

        print('✅ Successfully synced ${ordersToSync.length} orders');
      }
    } catch (e) {
      print('❌ Syncing error: $e');
    }
  }

  Future<void> _refreshAppControllerOrders() async {
    try {
      if (bearerKey == null || storeId == null) return;

      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);

      final Map<String, dynamic> data = {
        "store_id": storeId,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };

      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);

      if (result.isNotEmpty && result.first.code == null) {
        // ✅ Update AppController (this will refresh both OrderScreen and POS)
        app.appController.forceSetAllOrders(result);
        print('✅ AppController orders refreshed after sync');
      }
    } catch (e) {
      print('❌ Error refreshing AppController orders: $e');
    }
  }

  Future<Map<String, dynamic>> _buildSyncOrderMap(Map<String, dynamic> orderDetails) async {
    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final itemsData = orderDetails['items'] as List<dynamic>;
    final paymentData = orderDetails['payment'] as Map<String, dynamic>?;
    final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;

    int storedMillis = orderData['created_at'] as int;
    DateTime utcTime = DateTime.fromMillisecondsSinceEpoch(storedMillis, isUtc: true);
    String isoTimestamp = utcTime.toIso8601String();

    List<Map<String, dynamic>> items = [];
    for (var item in itemsData) {
      List<Map<String, dynamic>> toppings = [];
      if (item['toppings'] != null && item['toppings'] is List) {
        for (var t in item['toppings']) {
          toppings.add({
            'topping_id': t['id'] ?? 0,
            'quantity': t['topping_quantity'] ?? 1,
          });
        }
      }

      items.add({
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0.0,
        'note': item['note'] ?? '',
        'variant_id': item['variant_id'] ?? 0,
        'toppings': toppings,
      });
    }

    return {
      'client_uuid': orderData['client_uuid'],
      'store_id': int.tryParse(orderData['store_id'].toString()) ?? 0,
      'order_type': orderData['order_type'] ?? 3,
      'created_at': isoTimestamp,
      'note': orderData['note'] ?? '',
      'items': items,
      'delivery_time': orderData['delivery_time'],
      'payment': {
        'payment_method': 'cash',
        'status': 'paid',
        'amount': (paymentData?['amount'] as num?)?.toDouble() ?? 0.0,
        'order_id': 0,
      },
      'customer': {
        "customer_name": addressData?['customer_name'] ?? 'Walk-in Customer',
        "phone": addressData?['phone'],
        "email": orderData['email'],
        "line1": addressData?['line1'],
        "city": addressData?['city'],
        "zip": addressData?['zip'],
        "country": addressData?['country']
      },
    };
  }

  String formatAmount(double amount) {
    return NumberFormat('#,##0.0#', 'en_US').format(amount);
  }

  String extractTime(String deliveryTime) {
    try {
      DateTime dateTime = DateTime.parse(deliveryTime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return deliveryTime;
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 1: return Colors.orange;
      case 2: return Colors.green;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData getStatusIcon(int status) {
    switch (status) {
      case 1: return Icons.visibility;
      case 2: return Icons.check;
      case 3: return Icons.close;
      default: return Icons.help;
    }
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1: return "Pending";
      case 2: return "Accepted";
      case 3: return "Declined";
      default: return "Unknown";
    }
  }




}

// Models
class CategoryData {
  final String name;
  final Image? image;
  final List<Product> products;
  final String? id;
  final String? imageUrl;

  CategoryData({
    required this.name,
    this.image,
    required this.products,
    this.id,
    this.imageUrl,
  });

  factory CategoryData.fromGetProductCategory(
      GetProductCategoryList apiCategory,
      List<GetStoreProducts> allProducts,
      ) {
    List<Product> categoryProducts = allProducts
        .where((p) => p.categoryId == apiCategory.id && (p.isActive ?? false))
        .map((p) => Product.fromGetStoreProducts(p))
        .toList();

    return CategoryData(
      name: apiCategory.name ?? '',
      products: categoryProducts,
      id: apiCategory.id.toString(),
      imageUrl: apiCategory.imageUrl,
    );
  }
}

class Product {
  final String name;
  final double price;
  final bool isSpicy;
  final bool isVeg;
  final String? id;
  final String? categoryId;
  final String? imageUrl;
  final String? description;

  Product(
      this.name,
      this.price, {
        this.isSpicy = false,
        this.isVeg = false,
        this.id,
        this.categoryId,
        this.imageUrl,
        this.description,
      });

  factory Product.fromGetStoreProducts(GetStoreProducts apiProduct) {
    return Product(
      apiProduct.name ?? '',
      double.tryParse(apiProduct.price?.toString() ?? '0') ?? 0.0,
      id: apiProduct.id.toString(),
      categoryId: apiProduct.categoryId.toString(),
      imageUrl: apiProduct.imageUrl,
      description: apiProduct.description,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});
}
