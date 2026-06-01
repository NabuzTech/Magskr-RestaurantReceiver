import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/order_model.dart';
import '../../utils/my_application.dart';
import '../Order/OrderDetailEnglish.dart';
import 'pos_portrait_controller.dart';

class PosPortrait extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const PosPortrait({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PosPortraitController());

    return WillPopScope(
      onWillPop: () async {
        if (controller.showOrderOverlay.value) {
          controller.hideOrderOverlay();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffFAFCFF),
        body: Obx(() {
          if (controller.showOrderOverlay.value) {
            return _buildOrdersSection(controller, context);
          }
          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  _buildPortraitHeader(controller),
                  Expanded(
                    child: Row(
                      children: [
                        Obx(() {
                          if (!controller.isSearching.value) {
                            return _buildPortraitSidebar(controller);
                          }
                          return const SizedBox.shrink();
                        }),
                        Expanded(
                          child: _buildPortraitContent(controller, context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Obx(() {
                if (controller.totalItems.value > 0) {
                  return _buildCartBar(controller);
                }
                return const SizedBox.shrink();
              }),
              VariantDialog(controller: controller),
              PostcodeDialog(controller: controller),
              Obx(() {
                if (controller.showTimeBottomSheet.value) {
                  return GestureDetector(
                    onTap: () => controller.showTimeBottomSheet.value = false,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () {},
                          child: TimeSelectionBottomSheet(controller: controller),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPortraitHeader(PosPortraitController controller) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/mirch.png', height: 25, width: 25),
          Container(
            width: 250,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffDDEAFF), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 15, color: Colors.black),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Mulish',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search item',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Mulish',
                        fontStyle: FontStyle.italic,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Obx(() {
                  if (controller.searchQuery.value.isNotEmpty) {
                    return GestureDetector(
                      onTap: controller.clearSearch,
                      child: const Icon(Icons.clear, size: 15, color: Colors.grey),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          Obx(() => GestureDetector(
            onTap: controller.isRefreshing.value ? null : controller.refreshData,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xffDDEAFF), width: 1),
              ),
              child: controller.isRefreshing.value
                  ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xffE31E24)),
                ),
              )
                  : const Icon(
                Icons.refresh,
                color: Color(0xffE31E24),
                size: 15,
              ),
            ),
          )),
          // Orders icon with badge
          InkWell(
            onTap: () => controller.showOrdersOverlay(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset('assets/images/order-icon.svg', height: 22, width: 22),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Obx(() => controller.pendingOrdersCount.value > 0
                      ? Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Color(0xffE31E24), shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text('${controller.pendingOrdersCount.value}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.w700, fontFamily: 'Mulish')),
                          ),
                        )
                      : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitSidebar(PosPortraitController controller) {
    return Obx(() {
      if (controller.productCategoryList.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            ScrollablePositionedList.builder(
              itemScrollController: controller.sidebarScrollController,
              itemPositionsListener: controller.sidebarPositionsListener,
              itemCount: controller.productCategoryList.length,
              itemBuilder: (context, index) {
                bool isSelected = controller.selectedCategoryIndex.value == index;
                var category = controller.productCategoryList[index];

                return GestureDetector(
                  onTap: () => controller.scrollToCategory(index),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xffE9F6EF) : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: controller.getTrimmedImageUrl(category.imageUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.fastfood,
                                size: 25,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            category.name ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontFamily: 'Mulish',
                              color: isSelected ? const Color(0xff0C831F) : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (controller.selectedCategoryIndex.value > 0)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: const Color(0xffE31E24),
                  margin: EdgeInsets.only(
                    top: controller.selectedCategoryIndex.value * 80.0,
                  ),
                  height: 80,
                ),
              ),
          ],
        ),
      );
    });
  }

  // ─── ORDERS SECTION ────────────────────────────────────────────────────

  Widget _buildOrdersSection(PosPortraitController controller, BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.hideOrderOverlay(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffFBF9FF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset('assets/images/mirch.png', height: 22, width: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Orders',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Mulish')),
                        Text(DateFormat('d MMMM, y').format(DateTime.now()),
                            style: const TextStyle(fontSize: 12, fontFamily: 'Mulish')),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Obx(() => Text('Total: ${controller.orderStats['totalOrders']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Mulish'))),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.loadOrders(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.refresh, color: Color(0xffE31E24), size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.syncLocalOrders(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.sync, color: Color(0xffE31E24), size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats row
          Obx(() => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _orderStatChip('Accepted ${controller.orderStats['accepted']}', Colors.green.withOpacity(0.1)),
                const SizedBox(width: 8),
                _orderStatChip('Declined ${controller.orderStats['declined']}', Colors.red.withOpacity(0.1)),
                const SizedBox(width: 8),
                _orderStatChip('Pickup ${controller.orderStats['pickup']}', Colors.blue.withOpacity(0.1)),
                const SizedBox(width: 8),
                _orderStatChip('Delivery ${controller.orderStats['delivery']}', Colors.purple.withOpacity(0.1)),
              ],
            ),
          )),
          // Orders list
          Expanded(child: _buildOrdersList(controller, context)),
        ],
      ),
    );
  }

  Widget _orderStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(text,
          style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildOrdersList(PosPortraitController controller, BuildContext context) {
    return Obx(() {
      if (controller.isLoadingOrders.value) {
        return Center(
          child: Lottie.asset('assets/animations/burger.json', width: 120, height: 120),
        );
      }
      final allOrders = [
        ...controller.localOrdersList,
        ...app.appController.searchResultOrder,
      ];
      if (allOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/empty.json', width: 120, height: 120),
              const Text('No Orders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey, fontFamily: 'Mulish')),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: allOrders.length,
        itemBuilder: (context, index) {
          final order = allOrders[index];
          final isLocal = controller.localOrdersList.contains(order);
          return _buildOrderCard(controller, order, isLocal);
        },
      );
    });
  }

  Widget _buildOrderCard(PosPortraitController controller, Order order, bool isLocalOrder) {
    DateTime dateTime;
    try {
      dateTime = order.isLocalOrder == true
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(order.createdAt.toString()))
          : DateTime.parse(order.createdAt.toString());
    } catch (_) {
      dateTime = DateTime.now();
    }

    String time = DateFormat('hh:mm a').format(dateTime);
    String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';
    String guestZip = order.guestShippingJson?.zip?.toString() ?? '';

    Color containerColor() {
      if (order.source == 'pos') return const Color(0xffF7F3FF);
      switch (order.approvalStatus) {
        case 2: return const Color(0xffEBFFF4);
        case 3: return const Color(0xffFFEFEF);
        default: return Colors.white;
      }
    }

    Color borderColor() {
      if (order.source == 'pos') return const Color(0xffB8ABD1);
      switch (order.approvalStatus) {
        case 2: return const Color(0xffC3F2D9);
        case 3: return const Color(0xffFFD0D0);
        default: return Colors.grey.withOpacity(0.2);
      }
    }

    return GestureDetector(
      onTap: () => Get.to(() => OrderDetailEnglish(order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor(), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.green,
                      child: SvgPicture.asset(
                        order.orderType == 1
                            ? 'assets/images/ic_delivery.svg'
                            : order.orderType == 2
                                ? 'assets/images/ic_pickup.svg'
                                : 'assets/images/table.svg',
                        height: 12,
                        width: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderType == 2
                              ? 'Pickup'
                              : (order.shipping_address?.zip?.toString() ?? guestZip),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Mulish'),
                        ),
                        if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
                          Text('Time: ${controller.extractTime(order.deliveryTime!)}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'Mulish')),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 3),
                    Text(time, style: const TextStyle(fontSize: 12, fontFamily: 'Mulish')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${order.shipping_address?.customer_name ?? guestName} / ${order.shipping_address?.phone ?? guestPhone}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, fontFamily: 'Mulish'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Order #${order.orderNumber ?? order.id ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'Mulish')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('€ ${controller.formatAmount(order.payment?.amount ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Mulish')),
                Row(
                  children: [
                    Text(
                      isLocalOrder ? 'Syncing' : controller.getApprovalStatusText(order.approvalStatus),
                      style: const TextStyle(fontSize: 12, fontFamily: 'Mulish'),
                    ),
                    const SizedBox(width: 4),
                    isLocalOrder
                        ? const _SyncIcon()
                        : CircleAvatar(
                            radius: 10,
                            backgroundColor: controller.getStatusColor(order.approvalStatus ?? 0),
                            child: Icon(
                              controller.getStatusIcon(order.approvalStatus ?? 0),
                              color: Colors.white,
                              size: 12,
                            ),
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

  Widget _buildPortraitContent(PosPortraitController controller, BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xffE31E24)),
          ),
        );
      }

      List<CategoryData> displayCategories = controller.isSearching.value
          ? controller.getFilteredCategories()
          : controller.categories;

      if (displayCategories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                controller.isSearching.value
                    ? 'No products found'
                    : 'No categories available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
        );
      }

      return ScrollablePositionedList.builder(
        itemScrollController: controller.mainScrollController,
        itemPositionsListener: controller.mainPositionsListener,
        itemCount: displayCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = displayCategories[categoryIndex];
          return _buildCategorySection(controller, category);
        },
      );
    });
  }

  Widget _buildCategorySection(PosPortraitController controller, CategoryData category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Mulish',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: category.products.length,
            itemBuilder: (context, index) {
              final product = category.products[index];
              return _buildProductCard(controller, product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(PosPortraitController controller, Product product) {
    GetStoreProducts? actualProduct = controller.productList.firstWhereOrNull(
          (p) => p.id.toString() == product.id,
    );

    return Obx(() {
      // ✅ Check if product is in cart
      bool isInCart = controller.cartItems.any((item) =>
      item['product_id'] == actualProduct?.id
      );

      int totalQuantity = 0;
      if (isInCart) {
        controller.cartItems.where((item) => item['product_id'] == actualProduct?.id)
            .forEach((item) => totalQuantity += (item['quantity'] as int));
      }

      return GestureDetector(
        onTap: () {
          if (actualProduct != null) {
            controller.showProductVariantDialog(actualProduct);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isInCart ? const Color(0xff0C831F) : Colors.grey.shade200,
              width: isInCart ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isInCart) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff0C831F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$totalQuantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ],
                          ),
                          Text(
                            '€${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                              color: isInCart ? const Color(0xff0C831F) : const Color(0xff0B1928),
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCartBar(PosPortraitController controller) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          // ✅ Navigate to full screen checkout instead of bottom sheet
          Get.to(
                () => CheckoutScreen(controller: controller),
            transition: Transition.rightToLeft,
          );
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff0C831F),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffE31E24).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset('assets/images/cart.svg'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${controller.totalPrice.value.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        Text(
                          'item: ${controller.totalItems.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class CheckoutScreen extends StatelessWidget {
  final PosPortraitController controller;

  const CheckoutScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Phone Number / Name',
                        style: TextStyle(fontSize: 14, fontFamily: 'Mulish', color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Draft button
                  Obx(() => GestureDetector(
                    onTap: () => controller.toggleDraftPanel(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: controller.showDraftPanel.value
                            ? const Color(0xff6C4AB6)
                            : controller.drafts.isNotEmpty
                                ? const Color(0xff6C4AB6).withOpacity(0.15)
                                : const Color(0xffEDE4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(Icons.bookmark_outline_rounded, size: 20,
                              color: controller.showDraftPanel.value ? Colors.white : const Color(0xff6C4AB6)),
                          if (controller.drafts.isNotEmpty)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                width: 14, height: 14,
                                decoration: const BoxDecoration(color: Color(0xff6C4AB6), shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${controller.drafts.length}',
                                      style: const TextStyle(fontSize: 8, color: Colors.white,
                                          fontWeight: FontWeight.w700, fontFamily: 'Mulish')),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.onAddCustomerPressed(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffB8ABD1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/add-user.svg',
                        height: 20, width: 20, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Draft panel
            Obx(() {
              if (!controller.showDraftPanel.value) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xffEDE4FF)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Saved Drafts',
                              style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 14)),
                          GestureDetector(
                            onTap: () => controller.showDraftPanel.value = false,
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xffEDE4FF)),
                    Obx(() {
                      if (controller.drafts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No saved drafts',
                              style: TextStyle(fontFamily: 'Mulish', fontSize: 13, color: Colors.grey)),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(10),
                          itemCount: controller.drafts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final draft = controller.drafts[index];
                            final List items = draft['cartItems'] as List;
                            final Map details = draft['customerDetails'] as Map;
                            final String name = details['name']?.toString().isNotEmpty == true
                                ? details['name'].toString()
                                : details['phone']?.toString().isNotEmpty == true
                                    ? details['phone'].toString()
                                    : 'Draft ${index + 1}';
                            final DateTime savedAt = DateTime.parse(draft['savedAt']);
                            final String timeStr =
                                '${savedAt.hour.toString().padLeft(2, '0')}:${savedAt.minute.toString().padLeft(2, '0')}';
                            return GestureDetector(
                              onTap: () => controller.loadDraft(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xffEDE4FF)),
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xffFBF9FF),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff6C4AB6).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.bookmark_rounded, size: 14, color: Color(0xff6C4AB6)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w600, fontSize: 13),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text('${items.length} item${items.length == 1 ? '' : 's'}  •  $timeStr',
                                              style: const TextStyle(fontFamily: 'Mulish', fontSize: 11, color: Color(0xff797878))),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => controller.deleteDraft(index),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),

            // Order Type Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildOrderTypeBtn(controller, 'Lieferzeit', 'assets/images/delivery-icon.svg'),
                  const SizedBox(width: 8),
                  _buildOrderTypeBtn(controller, 'Abholzeit', 'assets/images/pickup-icon.svg'),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => controller.showAddNoteDialog(context),
                    child: Row(
                      children: [
                        Image.asset('assets/images/note.png', height: 16, width: 16),
                        const SizedBox(width: 4),
                        Obx(() => Text(
                          controller.orderNote.value.isEmpty ? 'Edit Note' : 'Note',
                          style: const TextStyle(fontSize: 12, fontFamily: 'Mulish'),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ Fixed Summary Box with Dropdown
                    _buildCollapsibleSummary(controller),

                    const SizedBox(height: 16),

                    // Customer Details Section
                    Obx(() {
                      if (controller.customerDetails.isEmpty) {
                        return _buildCustomerDetailsForm(controller, context);
                      } else {
                        return _buildCustomerDetailsDisplay(controller);
                      }
                    }),

                    const SizedBox(height: 16),

                    // Time Selection Section (Heute/Vorbestellen)
                    _buildTimeSelectionSection(controller, context),

                    const SizedBox(height: 16),

                    // Payment Method Section
                   // _buildPaymentMethodSection(controller),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom Draft + Weiter Buttons
            Obx(() {
              final bool hasItems = controller.cartItems.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: hasItems ? () => controller.saveAsDraft() : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: hasItems ? const Color(0xff6C4AB6) : const Color(0xffB8ABD1),
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Draft',
                                  style: TextStyle(color: Colors.white, fontSize: 14,
                                      fontWeight: FontWeight.w700, fontFamily: 'Mulish')),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.placeOrder(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xff0C831F),
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                          ),
                          child: const Center(
                            child: Text('Place Order',
                                style: TextStyle(color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.bold, fontFamily: 'Mulish')),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      // Postcode dialog overlay — visible on top of CheckoutScreen
      PostcodeDialog(controller: controller),
    ],
  ),
    );
  }

  Widget _buildOrderTypeBtn(PosPortraitController controller, String type, String iconPath) {
    return Obx(() {
      bool isSelected = controller.selectedOrderType.value == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.setOrderType(type),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xff0C831F) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xff0C831F) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  height: 16,
                  width: 16,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Mulish',
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ✅ Collapsible Summary Box
  Widget _buildCollapsibleSummary(PosPortraitController controller) {
    return Obx(() {
      double subtotal = controller.calculateSubtotal();
      double discount = controller.calculateDiscount();
      double grandTotal = controller.calculateGrandTotal();
      double discountPercent = controller.selectedOrderType.value == 'Lieferzeit'
          ? controller.deliveryDiscount.value
          : controller.pickupDiscount.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Text(
                        '${subtotal.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Discount (${discountPercent.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                          color: Color(0xff00B10E),
                        ),
                      ),
                      Text(
                        '${discount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: Color(0xff00B10E),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xffE0E0E0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${grandTotal.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.isCartExpanded.value = !controller.isCartExpanded.value,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xff0C831F),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.isCartExpanded.value
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cart Items (Collapsible)
            if (controller.isCartExpanded.value)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xffE0E0E0))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ...controller.cartItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      return _buildCartItemRow(controller, item, index);
                    }),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCartItemRow(PosPortraitController controller, Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Remove button
          GestureDetector(
            onTap: () => controller.removeCartItem(index),
            child: const Icon(Icons.close, size: 20, color: Color(0xffE31E24)),
          ),
          const SizedBox(width: 8),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.editItemNote(
                        index: index,
                        initial: item['item_note'] ?? '',
                        onSave: (v) => controller.updateItemNote(index, v),
                      ),
                      child: Image.asset(
                        'assets/images/note.png',
                        height: 14,
                        width: 14,
                        color: item['item_note'] != null && item['item_note'].toString().isNotEmpty
                            ? const Color(0xff0C831F)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item["size"]} • €${(item["price"] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Mulish',
                    color: Colors.grey,
                  ),
                ),
                if (item['extras'] != null && item['extras'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['extras'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Mulish',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                if (item['item_note'] != null && item['item_note'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: ${item["item_note"]}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Quantity controls
          Row(
            children: [
              GestureDetector(
                onTap: () => controller.decrementQuantity(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${item["quantity"]}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => controller.incrementQuantity(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Total price
          Text(
            '€ ${((item["quantity"] as int) * (item["price"] as num)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsForm(PosPortraitController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/images/user.svg', height: 16, width: 16),
              const SizedBox(width: 8),
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(controller.nameController, 'Ihre Name *', context),
          const SizedBox(height: 12),
          _buildTextField(controller.phoneController, 'Ihre Telefonnummer *', context),
          const SizedBox(height: 12),
          _buildTextField(controller.addressController, 'Straße und Hausnummer *', context),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: controller.selectedOrderType.value == 'Lieferzeit'
                ? () => controller.showPostcodeDialog.value = true
                : null,
            child: AbsorbPointer(
              absorbing: controller.selectedOrderType.value == 'Lieferzeit',
              child: _buildTextField(
                controller.regionController,
                controller.selectedOrderType.value == 'Lieferzeit'
                    ? 'Wählen Sie Ihre Region *'
                    : 'Region *',
                context,
                suffixIcon: controller.selectedOrderType.value == 'Lieferzeit'
                    ? const Icon(Icons.arrow_drop_down)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(controller.emailController, 'Ihre E-Mail', context),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      BuildContext context, {
        Widget? suffixIcon,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Mulish',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label.replaceAll('*', '').trim(),
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontFamily: 'Mulish',
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xff0C831F)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsDisplay(PosPortraitController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF7F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE6E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/images/user.svg', height: 16, width: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Customer Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: controller.editCustomerDetails,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.asset('assets/images/note.png', height: 18, width: 18),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xffE6E1EE)),
          _buildDetailRow('Ihre Name', controller.customerDetails['name'] ?? ''),
          const SizedBox(height: 8),
          _buildDetailRow('Ihre Telefonnummer', controller.customerDetails['phone'] ?? ''),
          const SizedBox(height: 8),
          _buildDetailRow('Ihre E-Mail', controller.customerDetails['email'] ?? ''),
          const SizedBox(height: 8),
          _buildDetailRow('Address', controller.customerDetails['address'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Mulish',
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'Mulish',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelectionSection(PosPortraitController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Heute
          Obx(() => GestureDetector(
            onTap: () => controller.selectHeute(),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: controller.isHeuteSelected.value
                      ? Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xff0C831F),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Heute',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                  ),
                ),
              ],
            ),
          )),

          if (controller.isHeuteSelected.value) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => controller.showTimeBottomSheet.value = true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xffFBF9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      controller.selectedTimeSlot.value,
                      style: const TextStyle(fontSize: 14, fontFamily: 'Mulish'),
                    )),
                    const Icon(Icons.access_time, size: 20),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Vorbestellen
          Obx(() => GestureDetector(
            onTap: () => controller.selectVorbestellen(),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: controller.isVorbestellenSelected.value
                      ? Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xff0C831F),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Vorbestellen',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mulish',
                  ),
                ),
              ],
            ),
          )),

          if (controller.isVorbestellenSelected.value) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => controller.selectVorbestellenDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xffFBF9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      controller.selectedVorbestellenDate.value != null
                          ? DateFormat('dd.MM.yyyy').format(controller.selectedVorbestellenDate.value!)
                          : 'Select Date',
                      style: const TextStyle(fontSize: 14, fontFamily: 'Mulish'),
                    )),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xffE31E24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
// Variant Dialog Widget
class VariantDialog extends StatelessWidget {
  final PosPortraitController controller;

  const VariantDialog({super.key, required this.controller});

  static const _green = Color(0xff0C831F);
  static const _lightGreen = Color(0xffE9F6EF);
  static const _border = Color(0xffE1E8F1);

  double _calculateTotal() {
    if (controller.selectedProduct.value == null) return 0.0;
    double base = double.tryParse(controller.selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variant = (controller.selectedVariant.value?.price ?? 0).toDouble();
    double toppings = 0.0;
    final variantId = controller.selectedVariant.value?.id;
    if (variantId != null) {
      final ids = controller.selectedToppingsMap[variantId] ?? [];
      controller.selectedVariant.value?.enrichedToppingGroups?.forEach((g) {
        g.toppings?.forEach((t) {
          if (t.id != null && ids.contains(t.id)) toppings += t.price ?? 0.0;
        });
      });
    }
    return base + variant + toppings;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showVariantDialog.value || controller.selectedProduct.value == null) {
        return const SizedBox.shrink();
      }

      final product = controller.selectedProduct.value!;

      return GestureDetector(
        onTap: () {
          controller.showVariantDialog.value = false;
          controller.variantNoteController.clear();
          controller.variantGroupErrors.clear();
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.showVariantDialog.value = false;
                              controller.variantNoteController.clear();
                              controller.variantGroupErrors.clear();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xffE1E8F1)),
                              ),
                              child: const Icon(Icons.close, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Variants grid ─────────────────────────────
                            if ((product.variants?.isNotEmpty ?? false)) ...[
                              const Text('Choose Variant',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish', color: Color(0xff475569))),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 2.4,
                                ),
                                itemCount: product.variants!.length,
                                itemBuilder: (context, i) {
                                  final variant = product.variants![i];
                                  return Obx(() {
                                    final isSelected = controller.selectedVariant.value?.id == variant.id;
                                    return GestureDetector(
                                      onTap: () => controller.selectVariant(variant),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected ? _green : _border,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          color: isSelected ? _lightGreen : Colors.white,
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(variant.name ?? '',
                                                      style: TextStyle(fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          fontFamily: 'Mulish',
                                                          color: isSelected ? _green : const Color(0xff475569)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                                if (isSelected)
                                                  const Icon(Icons.check_circle, color: _green, size: 16),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text('€${(variant.price ?? 0).toStringAsFixed(2)}',
                                                style: TextStyle(fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'Mulish',
                                                    color: isSelected ? _green : const Color(0xff475569))),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── Toppings for selected variant ─────────────
                            Obx(() {
                              final selVariant = controller.selectedVariant.value;
                              if (selVariant == null) return const SizedBox.shrink();
                              final isExpanded = controller.expandedVariantId.value == selVariant.id;
                              if (!isExpanded) return const SizedBox.shrink();
                              final groups = selVariant.enrichedToppingGroups ?? [];
                              if (groups.isEmpty) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: groups.map((group) {
                                  final bool isRequired = group.isRequired == true;
                                  final int minSel = group.minSelect ?? 0;
                                  final int maxSel = group.maxSelect ?? 0;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Group header
                                      Row(
                                        children: [
                                          Text(group.name?.toUpperCase() ?? 'TOPPINGS',
                                              style: const TextStyle(fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Mulish',
                                                  color: Color(0xff475569),
                                                  letterSpacing: 0.5)),
                                          if (isRequired)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('Required',
                                                  style: TextStyle(fontSize: 10,
                                                      color: _green,
                                                      fontWeight: FontWeight.w700,
                                                      fontFamily: 'Mulish')),
                                            ),
                                        ],
                                      ),
                                      if (isRequired && minSel > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Select $minSel${maxSel > minSel ? ' - $maxSel' : ''} item(s)',
                                          style: TextStyle(fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Mulish'),
                                        ),
                                      ],
                                      // Group error
                                      Obx(() {
                                        final err = controller.variantGroupErrors[group.id ?? 0];
                                        if (err == null) return const SizedBox.shrink();
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Text(err,
                                              style: TextStyle(color: Colors.red.shade700,
                                                  fontSize: 12, fontFamily: 'Mulish')),
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                      // Topping items
                                      ...(group.toppings ?? []).map((topping) {
                                        return Obx(() {
                                          final isToppingSelected = controller
                                              .selectedToppingsMap[selVariant.id]
                                              ?.contains(topping.id) ?? false;
                                          return GestureDetector(
                                            onTap: () => controller.toggleVariantTopping(
                                              selVariant.id!,
                                              topping.id!,
                                              groupId: group.id,
                                              maxSelect: maxSel > 0 ? maxSel : null,
                                            ),
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isToppingSelected ? _green : _border,
                                                  width: isToppingSelected ? 1.5 : 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                color: isToppingSelected ? _lightGreen : Colors.white,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(topping.name ?? '',
                                                        style: TextStyle(fontSize: 14,
                                                            fontFamily: 'Mulish',
                                                            fontWeight: isToppingSelected
                                                                ? FontWeight.w600
                                                                : FontWeight.w500,
                                                            color: const Color(0xff475569))),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text('€${(topping.price ?? 0).toStringAsFixed(2)}',
                                                      style: TextStyle(fontSize: 14,
                                                          fontFamily: 'Mulish',
                                                          fontWeight: FontWeight.w600,
                                                          color: isToppingSelected
                                                              ? _green
                                                              : const Color(0xff475569))),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 20, height: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isToppingSelected ? _green : Colors.transparent,
                                                      border: Border.all(
                                                          color: isToppingSelected ? _green : Colors.grey.shade400,
                                                          width: 1.5),
                                                    ),
                                                    child: isToppingSelected
                                                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        });
                                      }),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                }).toList(),
                              );
                            }),

                            // ── Item note field ───────────────────────────
                            const Text('Special Request',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                    color: Color(0xff475569))),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xffF5F7FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: TextField(
                                controller: controller.variantNoteController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13, fontFamily: 'Mulish'),
                                decoration: InputDecoration(
                                  hintText: 'e.g. no onions, extra sauce...',
                                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Add to Cart Button ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade200))),
                      child: Obx(() {
                        final hasVariant = controller.selectedVariant.value != null;
                        final total = _calculateTotal();
                        return GestureDetector(
                          onTap: () => controller.addToCartWithVariant(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: hasVariant ? _green : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                hasVariant
                                    ? 'In den Warenkorb  •  €${total.toStringAsFixed(2)}'
                                    : 'Bitte Variante wählen',
                                style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Mulish',
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Postcode Dialog Widget
class PostcodeDialog extends StatelessWidget {
  final PosPortraitController controller;

  const PostcodeDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showPostcodeDialog.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => controller.showPostcodeDialog.value = false,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent dialog from closing when tapping inside
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Postleitzahl wählen',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          IconButton(
                            onPressed: () => controller.showPostcodeDialog.value = false,
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Postcode list
                    Flexible(
                      child: controller.postcode.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Keine Postleitzahlen verfügbar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.postcode.length,
                        itemBuilder: (context, index) {
                          final postcode = controller.postcode[index];
                          final isSelected = controller.selectedPostcode.value?.id == postcode.id;
                          return GestureDetector(
                            onTap: () => controller.selectPostcode(postcode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xffE9F6EF)
                                    : Colors.white,
                                border: const Border(
                                  bottom: BorderSide(
                                    color: Colors.grey,
                                    width: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    postcode.postcode ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontFamily: 'Mulish',
                                      color: isSelected ? const Color(0xff0C831F) : Colors.black,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xff0C831F),
                                      size: 20,
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
          ),
        ),
      );
    });
  }
}

// Time Selection Bottom Sheet Widget
class TimeSelectionBottomSheet extends StatelessWidget {
  final PosPortraitController controller;

  const TimeSelectionBottomSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lieferzeit wählen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Mulish',
                  ),
                ),
                IconButton(
                  onPressed: () => controller.showTimeBottomSheet.value = false,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Date selection tabs
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectDateTab('heute'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.isHeuteSelected.value
                            ? const Color(0xff0C831F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.isHeuteSelected.value
                              ? const Color(0xff0C831F)
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Heute',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                          color: controller.isHeuteSelected.value
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.selectDateTab('vorbestellen'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: controller.isVorbestellenSelected.value
                            ? const Color(0xff0C831F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.isVorbestellenSelected.value
                              ? const Color(0xff0C831F)
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Vorbestellen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                          color: controller.isVorbestellenSelected.value
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: controller.isHeuteSelected.value
                ? _buildTodayTimeSlots()
                : _buildCalendarView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTimeSlots() {
    return Obx(() {
      if (controller.sofortTimeSlots.isEmpty) {
        return const Center(
          child: Text(
            'Keine Zeitfenster verfügbar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Mulish',
            ),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: controller.sofortTimeSlots.length,
        itemBuilder: (context, index) {
          final timeSlot = controller.sofortTimeSlots[index];
          final time = timeSlot['time'] ?? '';
          final isSelected = controller.selectedTimeSlot.value == time;

          return GestureDetector(
            onTap: () => controller.selectTimeSlot(time, 'heute'),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff0C831F) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xff0C831F)
                      : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Mulish',
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCalendarView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar would go here - you can use a calendar package
          // For now, showing a simple date picker button
          GestureDetector(
            onTap: () => controller.selectVorbestellenDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF7F3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffB8ABD1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xffE31E24)),
                  const SizedBox(width: 12),
                  Text(
                    controller.selectedVorbestellenDate.value != null
                        ? DateFormat('dd.MM.yyyy').format(
                        controller.selectedVorbestellenDate.value!)
                        : 'Datum auswählen',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
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
}

// Spinning sync icon for local (unsynced) orders
class _SyncIcon extends StatefulWidget {
  const _SyncIcon();

  @override
  State<_SyncIcon> createState() => _SyncIconState();
}

class _SyncIconState extends State<_SyncIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: const Icon(Icons.sync, size: 16, color: Colors.orange),
    );
  }
}