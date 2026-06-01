import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Database/databse_helper.dart';
import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/Payment.dart';
import '../../models/ShippingAddress.dart';
import '../../models/get_product_category_list_response_model.dart';
import '../../models/get_store_products_response_model.dart';

import '../../models/get_store_postcode_response_model.dart';
import '../../models/get_store_timing_response_model.dart';
import '../../models/order_model.dart';
import '../../models/sync_order_response_model.dart';
import '../../utils/my_application.dart';

class PosPortraitController extends GetxController {
  // Search
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final searchController = TextEditingController();
  final orderNote = ''.obs;
  // Category Selection
  final selectedCategoryIndex = 0.obs;
  final isCartExpanded = true.obs;
  // Cart
  final cart = <String, CartItem>{}.obs;
  final totalPrice = 0.0.obs;
  final totalItems = 0.obs;

  // Data Lists
  final productCategoryList = <GetProductCategoryList>[].obs;
  final productList = <GetStoreProducts>[].obs;
  final categories = <CategoryData>[].obs;

  // Loading States
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  // Scrollable Positioned List Controllers
  final ItemScrollController mainScrollController = ItemScrollController();
  final ItemPositionsListener mainPositionsListener = ItemPositionsListener.create();
  final ItemScrollController sidebarScrollController = ItemScrollController();
  final ItemPositionsListener sidebarPositionsListener = ItemPositionsListener.create();
// Add after existing observables
  final selectedProduct = Rx<GetStoreProducts?>(null);
  final selectedVariant = Rx<Variants?>(null);
  final selectedToppings = <String>[].obs;
  final showVariantDialog = false.obs;
  final expandedVariantId = Rx<int?>(null);
  final selectedToppingsMap = <int, List<int>>{}.obs;
  // Auto Scrolling Flag
  final isAutoScrolling = false.obs;
// Order management
  final selectedOrderType = 'Lieferzeit'.obs;
  final selectedTimeSlot = 'sofort'.obs;
  final showTimeBottomSheet = false.obs;
  final isHeuteSelected = true.obs;
  final isVorbestellenSelected = false.obs;
  final selectedVorbestellenDate = Rx<DateTime?>(null);
  final showCalendar = false.obs;
  final selectedDate = Rx<DateTime?>(null);
  final isStoreOpen = false.obs;
  // Customer details
  final isCustomerFormVisible = true.obs;
  final showCustomerDetails = false.obs;
  final customerDetails = <String, String>{}.obs;

  // Controllers (already present, but ensuring they exist)
  final noteController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final regionController = TextEditingController();

  // Focus nodes (already present, but ensuring they exist)
  final nameFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final addressFocusNode = FocusNode();
  final regionFocusNode = FocusNode();

  // Postcode
  final postcode = <GetStorePostCodesResponseModel>[].obs;
  final selectedPostcode = Rx<GetStorePostCodesResponseModel?>(null);
  final showPostcodeDialog = false.obs;

  // Timing
  final List<Map<String, String>> sofortTimeSlots = <Map<String, String>>[].obs;
  final storeOpeningTime = Rx<DateTime?>(null);
  List<GetStoreTimingResponseModel> storeTimingList = [];

  // Discount
  final discountPercentage = 0.0.obs;
  final deliveryDiscount = 0.0.obs;
  final pickupDiscount = 0.0.obs;
  String? deliveryDiscountId;
  String? pickupDiscountId;

  // Payment
  final selectedPaymentMethod = 'cash'.obs;
  final isProcessingOrder = false.obs;

  // Invoice
  final invoiceNumber = 1.obs;
  final pendingOrdersCount = 0.obs;

  // Variant dialog note & errors
  final variantNoteController = TextEditingController();
  final variantGroupErrors = <int, String>{}.obs;

  // Drafts
  final drafts = <Map<String, dynamic>>[].obs;
  final showDraftPanel = false.obs;

  // Orders overlay
  final showOrderOverlay = false.obs;
  final isLoadingOrders = false.obs;
  final localOrdersList = <Order>[].obs;
  final orderStats = <String, int>{
    'totalOrders': 0,
    'accepted': 0,
    'declined': 0,
    'pickup': 0,
    'delivery': 0,
  }.obs;

  String? bearerKey;

  // Database Helper
  final dbHelper = DatabaseHelper();
  final showTimeSelector = false.obs;

  // Store ID
  String? storeId;
  SharedPreferences? sharedPreferences;

  @override
  void onInit() {
    super.onInit();
    _initializeSharedPreferences();
    _setupScrollListener();
    _loadNextInvoiceNumber();
    _loadPendingOrdersCount();
  }


  @override
  void onClose() {
    searchController.dispose();
    noteController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    regionController.dispose();
    nameFocusNode.dispose();
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    addressFocusNode.dispose();
    regionFocusNode.dispose();
    variantNoteController.dispose();
    showVariantDialog.value = false;
    showPostcodeDialog.value = false;
    showTimeBottomSheet.value = false;
    super.onClose();
  }

  void _setupScrollListener() {
    mainPositionsListener.itemPositions.addListener(_onMainScroll);
  }

  void _onMainScroll() {
    if (isAutoScrolling.value || isSearching.value) return;

    final positions = mainPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the first visible category
    final visiblePositions = positions
        .where((position) => position.itemLeadingEdge >= -0.3)
        .toList();

    if (visiblePositions.isEmpty) return;

    final firstVisible = visiblePositions
        .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);

    int visibleIndex = firstVisible.index;

    if (visibleIndex != selectedCategoryIndex.value && visibleIndex < categories.length) {
      selectedCategoryIndex.value = visibleIndex;
      _scrollSidebarToCategory(visibleIndex);
    }
  }

  void _scrollSidebarToCategory(int index) {
    if (!sidebarScrollController.isAttached) return;

    try {
      sidebarScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    } catch (e) {
      print('Error scrolling sidebar: $e');
    }
  }

  Future<void> scrollToCategory(int index) async {
    if (isAutoScrolling.value || index >= categories.length) return;

    isAutoScrolling.value = true;
    selectedCategoryIndex.value = index;

    try {
      await mainScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.0,
      );

      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error scrolling to category: $e');
    } finally {
      isAutoScrolling.value = false;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
      bearerKey = sharedPreferences!.getString(valueShared_BEARER_KEY);

      if (storeId != null) {
        await getProductCategory();
        await getPostcodes();
        await getDiscountPercentage();
        await getStoreTiming();
      }
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      isLoading.value = false;
    }
  }

  Future<void> getProductCategory({bool showLoader = true, bool forceRefresh = false}) async {
    if (storeId == null) return;

    // Load from database first if not force refresh
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
    }

    try {
      print('📡 Fetching data from API...');
      List<GetProductCategoryList> categoryList = await CallService().getProductCategory(storeId!);
      List<GetStoreProducts> products = await CallService().getProducts(storeId!);

      // Save to database
      await dbHelper.saveCategories(categoryList, storeId!);
      await dbHelper.saveProducts(products, storeId!);

      productCategoryList.value = categoryList;
      productList.value = products;

      _buildCategories();

      print('✅ Categories loaded: ${categories.length}');

      isLoading.value = false;
      isRefreshing.value = false;

      if (showLoader && Get.context != null) {
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
    } catch (e) {
      print('❌ Error getting Product Category: $e');
      isLoading.value = false;
      isRefreshing.value = false;

      // Fallback to database
      await _loadFromDatabase();
    }
  }

  Future<void> _loadFromDatabase() async {
    try {
      print('📦 Loading from database...');

      List<GetProductCategoryList> categoryList = await dbHelper.getCategories(storeId!);
      List<GetStoreProducts> products = await dbHelper.getProducts(storeId!);

      if (categoryList.isEmpty || products.isEmpty) {
        print('⚠️ No data found in database');
        isLoading.value = false;
        return;
      }

      productCategoryList.value = categoryList;
      productList.value = products;

      _buildCategories();

      print('✅ Loaded ${categories.length} categories from database');
      isLoading.value = false;
    } catch (e) {
      print('❌ Error loading from database: $e');
      isLoading.value = false;
    }
  }

  void _buildCategories() {
    categories.value = productCategoryList
        .map((apiCategory) {
      return CategoryData.fromGetProductCategory(apiCategory, productList);
    })
        .where((cat) => cat.products.isNotEmpty)
        .toList();
  }

  Future<void> refreshData() async {
    print('🔄 Manual refresh triggered');
    await getProductCategory(showLoader: true, forceRefresh: true);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    isSearching.value = value.isNotEmpty;
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

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

  final cartItems = <Map<String, dynamic>>[].obs;

  void addToCart(GetStoreProducts product) {
    int existingIndex = cartItems.indexWhere((item) => item['name'] == product.name);

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
    if (selectedProduct.value == null || selectedVariant.value == null) {
      Get.snackbar('Error', 'Please select a variant',
          backgroundColor: Colors.red, colorText: Colors.white,
          duration: const Duration(seconds: 2));
      return;
    }

    // Required topping validation
    final variant = selectedVariant.value!;
    final selectedIds = selectedToppingsMap[variant.id] ?? [];
    bool hasError = false;

    for (var group in variant.enrichedToppingGroups ?? []) {
      if (group.isRequired == true && (group.minSelect ?? 0) > 0) {
        final selectedCount = group.toppings?.where((t) => selectedIds.contains(t.id)).length ?? 0;
        if (selectedCount < (group.minSelect ?? 0)) {
          variantGroupErrors[group.id ?? 0] =
              'Please select at least ${group.minSelect} item(s) from "${group.name}"';
          hasError = true;
        }
      }
    }
    if (hasError) {
      variantGroupErrors.refresh();
      return;
    }

    double basePrice = double.tryParse(selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variantPrice = (selectedVariant.value!.price ?? 0).toDouble();

    double toppingPrice = 0.0;
    List<String> toppingDetails = [];
    List<Map<String, dynamic>> toppingDataList = [];

    if (selectedToppingsMap.containsKey(selectedVariant.value!.id)) {
      var selectedToppingIds = selectedToppingsMap[selectedVariant.value!.id]!;

      selectedVariant.value!.enrichedToppingGroups?.forEach((group) {
        group.toppings?.forEach((topping) {
          if (selectedToppingIds.contains(topping.id)) {
            toppingPrice += topping.price ?? 0.0;
            toppingDetails.add('${topping.name} [€${(topping.price ?? 0.0).toStringAsFixed(2)}]');

            toppingDataList.add({
              'topping_id': topping.id,
              'name': topping.name,
              'price': topping.price ?? 0.0,
              'quantity': 1,
            });
          }
        });
      });
    }

    double totalPrice = basePrice + variantPrice + toppingPrice;
    String variantName = selectedVariant.value!.name ?? '';
    String itemKey = '${selectedProduct.value!.name}_${variantName}_${toppingDetails.join(',')}';

    int existingIndex = cartItems.indexWhere((item) => item['key'] == itemKey);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
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
        'topping_data': toppingDataList,
        'item_note': variantNoteController.text.trim(),
      });
    }

    calculateTotal();

    showVariantDialog.value = false;
    selectedProduct.value = null;
    selectedVariant.value = null;
    selectedToppingsMap.clear();
    expandedVariantId.value = null;
    variantGroupErrors.clear();
    variantNoteController.clear();
  }
  void addSimpleProductToCart(GetStoreProducts product) {
    double basePrice = double.tryParse(product.price?.toString() ?? '0') ?? 0.0;
    String itemKey = '${product.name}_no_variant';

    int existingIndex = cartItems.indexWhere((item) => item['key'] == itemKey);

    if (existingIndex != -1) {
      cartItems[existingIndex]['quantity']++;
    } else {
      cartItems.add({
        'key': itemKey,
        'name': product.name ?? '',
        'extras': '',
        'size': '',
        'quantity': 1,
        'price': basePrice,
        'variant_id': null,
        'product_id': product.id,
        'topping_details': [],
        'topping_data': [],
        'item_note': '',
      });
    }

    calculateTotal();
  }

  void onWeiterPressed() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'Warenkorb leer',
        'Bitte fügen Sie Artikel hinzu',
        backgroundColor: const Color(0xffE31E24),
        colorText: Colors.white,
      );
      return;
    }

    if (!showCustomerDetails.value) {
      // ✅ Show customer details form
      showCustomerDetails.value = true;
      isCustomerFormVisible.value = true;
    } else if (isCustomerFormVisible.value) {
      // ✅ Currently editing - do nothing or show message
      Get.snackbar(
        'Hinweis',
        'Bitte speichern Sie die Kundendetails',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      // ✅ Place order
      placeOrder();
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
        }
      }
    }

    // ✅ Check if product has variants
    if (product.variants != null && product.variants!.isNotEmpty) {
      showVariantDialog.value = true;
    } else {
      // ✅ No variants - add directly to cart
      addSimpleProductToCart(product);
    }
  }

  void addToCartPortrait(Product product) {
    if (cart.containsKey(product.id)) {
      cart[product.id]!.quantity++;
    } else {
      cart[product.name] = CartItem(product: product, quantity: 1);
    }
    calculateTotal();
  }

  void removeFromCartPortrait(int index) {
    if (index >= 0 && index < cartItems.length) {
      if (cartItems[index]['quantity'] > 1) {
        cartItems[index]['quantity']--;
      } else {
        cartItems.removeAt(index);
      }
      calculateTotal();
      cartItems.refresh();
    }
  }

  void calculateTotal() {
    totalPrice.value = 0.0;
    totalItems.value = 0;

    for (var item in cartItems) {
      totalPrice.value += (item['price'] as num) * (item['quantity'] as int);
      totalItems.value += (item['quantity'] as int);
    }
  }

  void incrementQuantity(int index) {
    cartItems[index]['quantity']++;
    calculateTotal();
    cartItems.refresh();
  }

  void decrementQuantity(int index) {
    if (cartItems[index]['quantity'] > 1) {
      cartItems[index]['quantity']--;
    } else {
      cartItems.removeAt(index);
    }
    calculateTotal();
    cartItems.refresh();
  }

  int getProductQuantity(Product product) {
    return cart[product.name]?.quantity ?? 0;
  }

  bool isProductSelected(Product product) {
    return cart.containsKey(product.name);
  }

  String getTrimmedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      return url.substring(0, queryIndex);
    }
    return url;
  }

  void selectVariant(Variants variant) {
    selectedToppingsMap.clear();
    variantGroupErrors.clear();
    variantNoteController.clear();
    expandedVariantId.value = null; // close previous dropdown first
    selectedVariant.value = variant;
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

  void toggleVariantTopping(int variantId, int toppingId, {int? groupId, int? maxSelect}) {
    if (!selectedToppingsMap.containsKey(variantId)) {
      selectedToppingsMap[variantId] = [];
    }
    if (selectedToppingsMap[variantId]!.contains(toppingId)) {
      selectedToppingsMap[variantId]!.remove(toppingId);
      if (groupId != null) {
        variantGroupErrors.remove(groupId);
        variantGroupErrors.refresh();
      }
    } else {
      // maxSelect check per group
      if (groupId != null && maxSelect != null && maxSelect > 0) {
        final currentGroupSelected = selectedVariant.value?.enrichedToppingGroups
            ?.firstWhere((g) => g.id == groupId, orElse: () => EnrichedToppingGroups())
            .toppings
            ?.where((t) => selectedToppingsMap[variantId]?.contains(t.id) == true)
            .length ?? 0;
        if (currentGroupSelected >= maxSelect) {
          variantGroupErrors[groupId] = 'Max $maxSelect selection(s) allowed';
          variantGroupErrors.refresh();
          return;
        }
      }
      selectedToppingsMap[variantId]!.add(toppingId);
    }
    selectedToppingsMap.refresh();
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

  Future<void> getPostcodes() async {
    if (storeId == null || storeId!.isEmpty) return;
    try {
      postcode.value = await CallService().getPostCode(storeId!);
      print('✅ Loaded ${postcode.length} postcodes');
    } catch (e) {
      print('❌ Error getting postcodes: $e');
    }
  }

  Future<void> getDiscountPercentage() async {
    if (storeId == null || storeId!.isEmpty) return;
    try {
      var discounts = await CallService().getDiscountPercentage(storeId!);
      if (discounts.isNotEmpty) {
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

  Future<void> getStoreTiming() async {
    if (storeId == null) return;
    try {
      storeTimingList = await CallService().getStoreTiming(storeId!);
      if (storeTimingList.isNotEmpty) {
        _generateTimeSlots();
      }
    } catch (e) {
      print('❌ Error getting store timing: $e');
    }
  }

  void _generateTimeSlots() {
    sofortTimeSlots.clear();
    DateTime now = DateTime.now();
    String currentDay = _getDayOfWeek(now.weekday);

    var todayTiming = storeTimingList.firstWhere(
          (timing) => timing.dayOfWeek?.toString() == currentDay.toLowerCase(),
      orElse: () => GetStoreTimingResponseModel(),
    );

    if (todayTiming.openingTime == null || todayTiming.closingTime == null) {
      print('⚠️ Store is closed today');
      return;
    }

    try {
      DateTime openingTime = DateFormat('HH:mm:ss').parse(todayTiming.openingTime!);
      DateTime closingTime = DateFormat('HH:mm:ss').parse(todayTiming.closingTime!);

      DateTime storeOpen = DateTime(now.year, now.month, now.day, openingTime.hour, openingTime.minute);
      DateTime storeClose = DateTime(now.year, now.month, now.day, closingTime.hour, closingTime.minute);

      DateTime startTime = now.isAfter(storeOpen) ? now.add(const Duration(minutes: 30)) : storeOpen;
      startTime = DateTime(startTime.year, startTime.month, startTime.day, startTime.hour, (startTime.minute ~/ 15) * 15);

      while (startTime.isBefore(storeClose)) {
        sofortTimeSlots.add({
          'time': DateFormat('HH:mm').format(startTime),
          'date': DateFormat('yyyy-MM-dd').format(startTime),
        });
        startTime = startTime.add(const Duration(minutes: 15));
      }

      print('✅ Generated ${sofortTimeSlots.length} time slots');
    } catch (e) {
      print('❌ Error generating time slots: $e');
    }
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  void setOrderType(String type) {
    selectedOrderType.value = type;
    // Reset customer form if switching to dine-in
    if (type == 'Dine-in') {
      isCustomerFormVisible.value = false;
    } else {
      isCustomerFormVisible.value = true;
    }
  }

  void toggleCustomerForm() {
    isCustomerFormVisible.value = !isCustomerFormVisible.value;
  }

  void selectPostcode(GetStorePostCodesResponseModel postcode) {
    selectedPostcode.value = postcode;
    showPostcodeDialog.value = false;
    regionController.text = postcode.postcode?? '';
  }

  void selectTimeOption(String option) {
    if (option == 'Sofort') {
      selectedTimeSlot.value = 'sofort';
      selectedVorbestellenDate.value = null;
    }
  }

  void selectDateTab(String tab) {
    if (tab == 'heute') {
      isHeuteSelected.value = true;
      isVorbestellenSelected.value = false;
    } else {
      isHeuteSelected.value = false;
      isVorbestellenSelected.value = true;
    }
  }

  void selectTimeSlot(String time, String type) {
    selectedTimeSlot.value = time;

    if (type == 'heute') {
      DateTime now = DateTime.now();
      List<String> timeParts = time.split(':');
      selectedVorbestellenDate.value = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    showTimeBottomSheet.value = false;
  }

  Future<void> selectVorbestellenDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        selectedVorbestellenDate.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        selectedTimeSlot.value = 'vorbestellen';
        showTimeBottomSheet.value = false;
      }
    }
  }

  void editItemNote({required int index, required String initial, required Function(String) onSave}) {
    TextEditingController noteEditController = TextEditingController(text: initial);

    Get.dialog(
      AlertDialog(
        title: const Text(
          'Notiz bearbeiten',
          style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: noteEditController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Notiz eingeben...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Abbrechen', style: TextStyle(fontFamily: 'Mulish')),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(noteEditController.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffE31E24),
            ),
            child: const Text('Speichern', style: TextStyle(fontFamily: 'Mulish', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void updateItemNote(int index, String note) {
    if (index >= 0 && index < cartItems.length) {
      cartItems[index]['item_note'] = note;
      cartItems.refresh();
    }
  }

  double calculateGrandTotal() {
    return calculateSubtotal() - calculateDiscount();
  }

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

  void removeCartItem(int index) {
    cartItems.removeAt(index);
    cartItems.refresh();
  }

  void editCustomerDetails() {
    isCustomerFormVisible.value = true;
    nameController.text = customerDetails['name'] ?? '';
    phoneController.text = customerDetails['phone'] ?? '';
    addressController.text = customerDetails['address'] ?? '';
    emailController.text = customerDetails['email'] ?? '';
    regionController.text = customerDetails['region'] ?? '';
  }

  void selectHeute() {
    isHeuteSelected.value = true;
    isVorbestellenSelected.value = false;
    selectedDate.value = null;
    showCalendar.value = false;
    showTimeSelector.value = false;
    //
    // // ✅ ADD THIS - Regenerate slots to check if store is open
    // _generateSofortTimeSlots();

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

  void _showSuccessDialog() {
    Get.back(); // Close checkout modal

    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/success.json',
              width: 150,
              height: 150,
              repeat: false,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bestellung erfolgreich!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ihre Bestellung wurde erfolgreich aufgegeben',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Mulish',
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Mulish',
                color: Color(0xffE31E24),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _clearOrderForm() {
    cartItems.clear();
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    regionController.clear();
    noteController.clear();
    selectedPostcode.value = null;
    selectedTimeSlot.value = 'sofort';
    selectedVorbestellenDate.value = null;
    selectedPaymentMethod.value = 'cash';
    calculateTotal();
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Fehler',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // ─── DRAFT ──────────────────────────────────────────────────────────────

  void toggleDraftPanel() => showDraftPanel.value = !showDraftPanel.value;

  void saveAsDraft() {
    if (cartItems.isEmpty) return;
    drafts.add({
      'cartItems': List<Map<String, dynamic>>.from(cartItems),
      'customerDetails': Map<String, String>.from(customerDetails),
      'orderNote': orderNote.value,
      'orderType': selectedOrderType.value,
      'savedAt': DateTime.now().toIso8601String(),
    });
    cartItems.clear();
    customerDetails.clear();
    nameController.clear();
    phoneController.clear();
    emailController.clear();
    addressController.clear();
    regionController.clear();
    orderNote.value = '';
    showCustomerDetails.value = false;
    isCustomerFormVisible.value = true;
    selectedPostcode.value = null;
    showDraftPanel.value = false;
    calculateTotal();
    Get.snackbar('Draft saved', 'Order saved as draft',
        backgroundColor: const Color(0xff6C4AB6),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM);
  }

  void loadDraft(int index) {
    if (index < 0 || index >= drafts.length) return;
    final draft = drafts[index];
    cartItems.value = List<Map<String, dynamic>>.from(draft['cartItems'] as List);
    final details = Map<String, String>.from(draft['customerDetails'] as Map);
    customerDetails.value = details;
    orderNote.value = draft['orderNote'] as String? ?? '';
    selectedOrderType.value = draft['orderType'] as String? ?? 'Lieferzeit';
    if (details.isNotEmpty) {
      nameController.text = details['name'] ?? '';
      phoneController.text = details['phone'] ?? '';
      emailController.text = details['email'] ?? '';
      addressController.text = details['address'] ?? '';
      regionController.text = details['region'] ?? '';
      showCustomerDetails.value = true;
      isCustomerFormVisible.value = false;
    }
    drafts.removeAt(index);
    calculateTotal();
    showDraftPanel.value = false;
  }

  void deleteDraft(int index) {
    if (index >= 0 && index < drafts.length) {
      drafts.removeAt(index);
    }
  }

  // ─── ORDERS OVERLAY ─────────────────────────────────────────────────────

  void showOrdersOverlay() {
    showOrderOverlay.value = true;
    loadOrders();
  }

  void hideOrderOverlay() => showOrderOverlay.value = false;

  Future<void> loadOrders() async {
    if (storeId == null) return;
    isLoadingOrders.value = true;
    try {
      final unsyncedRaw = await dbHelper.getUnsyncedOrders(storeId!);
      List<Order> localOrders = [];

      for (var dbOrder in unsyncedRaw) {
        final orderDetails = await dbHelper.getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          localOrders.add(await _buildOrderFromDetails(orderDetails));
        }
      }
      localOrdersList.value = localOrders;

      final allOrders = [...localOrdersList, ...app.appController.searchResultOrder];

      orderStats.value = {
        'totalOrders': allOrders.length,
        'accepted': allOrders.where((o) => o.approvalStatus == 2).length,
        'declined': allOrders.where((o) => o.approvalStatus == 3).length,
        'pickup': allOrders.where((o) => o.orderType == 2).length,
        'delivery': allOrders.where((o) => o.orderType == 1).length,
      };
    } catch (e) {
      print('❌ Error loading orders (portrait): $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  Future<Order> _buildOrderFromDetails(Map<String, dynamic> orderDetails) async {
    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;
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

    Payment? payment;
    if (paymentData != null) {
      payment = Payment(
        amount: (paymentData['amount'] as num?)?.toDouble(),
        paymentMethod: paymentData['payment_method'] as String?,
        status: paymentData['status'] as String?,
      );
    }

    return Order(
      id: orderData['id'] as int?,
      orderNumber: orderData['id'] as int?,
      orderType: orderData['order_type'] as int?,
      approvalStatus: orderData['approval_status'] as int?,
      note: orderData['note'] as String? ?? '',
      deliveryTime: orderData['delivery_time'] as String?,
      storeId: orderData['store_id'] != null ? int.tryParse(orderData['store_id'].toString()) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(orderData['created_at'] as int).toIso8601String(),
      shipping_address: shippingAddress,
      payment: payment,
      items: [],
      isLocalOrder: true,
    );
  }

  Future<void> syncLocalOrders() async {
    if (storeId == null) return;
    try {
      final unsyncedOrders = await dbHelper.getUnsyncedOrders(storeId!);
      if (unsyncedOrders.isEmpty) {
        Get.snackbar('Sync', 'No pending orders to sync',
            backgroundColor: const Color(0xff0C831F),
            colorText: Colors.white,
            duration: const Duration(seconds: 2));
        return;
      }

      List<int> localOrderIds = unsyncedOrders.map((o) => o['id'] as int).toList();
      List<Map<String, dynamic>> ordersToSync = [];

      for (var dbOrder in unsyncedOrders) {
        final orderDetails = await dbHelper.getOrderDetails(dbOrder['id'] as int);
        if (orderDetails != null) {
          ordersToSync.add(_buildSyncOrderMap(orderDetails));
        }
      }

      SyncLocalOrder model = await CallService().syncLocalOrder(ordersToSync);

      if (model.status == 'ok') {
        for (int localOrderId in localOrderIds) {
          await dbHelper.markOrderAsSynced(localOrderId);
        }
        pendingOrdersCount.value = 0;
        await loadOrders();
        Get.snackbar('Sync Complete', 'Orders synced successfully',
            backgroundColor: const Color(0xff0C831F),
            colorText: Colors.white,
            duration: const Duration(seconds: 2));
      }
    } catch (e) {
      print('❌ Error syncing orders (portrait): $e');
    }
  }

  Map<String, dynamic> _buildSyncOrderMap(Map<String, dynamic> orderDetails) {
    final orderData = orderDetails['order'] as Map<String, dynamic>;
    final itemsData = orderDetails['items'] as List<dynamic>;
    final paymentData = orderDetails['payment'] as Map<String, dynamic>?;
    final addressData = orderDetails['shipping_address'] as Map<String, dynamic>?;

    int storedMillis = orderData['created_at'] as int;
    String isoTimestamp = DateTime.fromMillisecondsSinceEpoch(storedMillis, isUtc: true).toIso8601String();

    List<Map<String, dynamic>> items = [];
    for (var item in itemsData) {
      List<Map<String, dynamic>> toppings = [];
      if (item['toppings'] != null && item['toppings'] is List) {
        for (var t in item['toppings']) {
          toppings.add({'topping_id': t['id'] ?? 0, 'quantity': t['topping_quantity'] ?? 1});
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
        'customer_name': addressData?['customer_name'] ?? 'Walk-in Customer',
        'phone': addressData?['phone'],
        'email': orderData['email'],
        'line1': addressData?['line1'],
        'city': addressData?['city'],
        'zip': addressData?['zip'],
        'country': addressData?['country'],
      },
    };
  }

  // ─── CUSTOMER HELPERS ───────────────────────────────────────────────────

  void onAddCustomerPressed() {
    showCustomerDetails.value = true;
    isCustomerFormVisible.value = true;
  }

  void toggleCustomerDetails() {
    isCartExpanded.value = !isCartExpanded.value;
  }

  void showPostcodeSelector(BuildContext context) {
    showPostcodeDialog.value = true;
  }

  void showItemNoteDialog(BuildContext context, int index) {
    final ctrl = TextEditingController(
        text: cartItems[index]['item_note']?.toString() ?? '');
    Get.dialog(AlertDialog(
      title: const Text('Item Note',
          style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Enter note...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xffE31E24))),
        ),
        style: const TextStyle(fontFamily: 'Mulish'),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Mulish', color: Colors.grey))),
        ElevatedButton(
            onPressed: () {
              updateItemNote(index, ctrl.text);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0C831F)),
            child: const Text('Save',
                style: TextStyle(
                    fontFamily: 'Mulish', color: Colors.white))),
      ],
    ));
  }

  // ─── ORDER DISPLAY HELPERS ──────────────────────────────────────────────

  String extractTime(String deliveryTime) {
    try {
      DateTime dt = DateTime.parse(deliveryTime);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return deliveryTime;
    }
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1: return 'Pending';
      case 2: return 'Accepted';
      case 3: return 'Declined';
      default: return 'Unknown';
    }
  }

  Color getStatusColor(int status) {
    switch (status) {
      case 2: return const Color(0xff0C831F);
      case 3: return const Color(0xffE31E24);
      default: return Colors.orange;
    }
  }

  IconData getStatusIcon(int status) {
    switch (status) {
      case 2: return Icons.check;
      case 3: return Icons.close;
      default: return Icons.access_time;
    }
  }

  String formatAmount(dynamic amount) {
    try {
      double val = double.tryParse(amount.toString()) ?? 0.0;
      return val.toStringAsFixed(2);
    } catch (_) {
      return '0.00';
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