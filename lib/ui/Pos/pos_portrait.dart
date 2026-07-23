import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/order_model.dart';
import '../../utils/my_application.dart';
import '../Order/OrderDetailEnglish.dart';
import 'pos_portrait_controller.dart';

class PosPortrait extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const PosPortrait({super.key, this.onNavigateToTab});

  @override
  State<PosPortrait> createState() => _PosPortraitState();
}

class _PosPortraitState extends State<PosPortrait> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Offset? _fabPosition;

  void _openTab(int index) {
    print("🎯 POS: Navigating to tab $index");

    // ✅ Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PosPortraitController());

    return WillPopScope(
      onWillPop: () async {
        if (controller.showOrderOverlay.value) {
          controller.hideOrderOverlay();
          return false;
        }
        if (controller.showCheckout.value) {
          controller.showCheckout.value = false;
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(onSelectTab: _openTab),
        backgroundColor: const Color(0xffFAFCFF),
        bottomNavigationBar: Obx(() {
          final showPosBar =
              !controller.showOrderTypeSelection.value &&
              !controller.showOrderOverlay.value &&
              !controller.showSavedOrdersScreen.value;
          if (!showPosBar) return const SizedBox.shrink();
          return _buildPosBottomBar(controller);
        }),
        body: Obx(() {
          if (controller.showOrderOverlay.value) {
            return _buildOrdersSection(controller, context);
          }
          if (controller.showSavedOrdersScreen.value) {
            return _buildSavedOrdersScreen(controller);
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              final offset = controller.showOrderTypeSelection.value
                  ? const Offset(0, -1) // selection screen: upar se aata hai
                  : const Offset(0, 1); // product screen: niche se aata hai
              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: controller.showOrderTypeSelection.value
                ? KeyedSubtree(
                    key: const ValueKey('selection'),
                    child: _buildOrderTypeSelectionScreen(controller),
                  )
                : controller.showCheckout.value
                ? KeyedSubtree(
                    key: const ValueKey('checkout'),
                    child: CheckoutScreen(controller: controller),
                  )
                : KeyedSubtree(
                    key: const ValueKey('main'),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 40),
                            // _buildPortraitHeader(controller),
                            _buildSelectedOrderTypeBar(controller),
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
                                    child: _buildPortraitContent(
                                      controller,
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _buildDraggableFab(controller, context),
                        VariantDialog(controller: controller),
                        PostcodeDialog(controller: controller),
                        Obx(() {
                          if (controller.showTimeBottomSheet.value) {
                            return GestureDetector(
                              onTap: () =>
                                  controller.showTimeBottomSheet.value = false,
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: TimeSelectionBottomSheet(
                                      controller: controller,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
          );
        }),
      ),
    );
  }

  // ── 1. Order Type Selection Screen (entry screen) ──────────────────
  Widget _buildOrderTypeSelectionScreen(PosPortraitController controller) {
    return SafeArea(
      child: Obx(() {
        if (controller.drafts.isEmpty) {
          // No saved orders yet — simple centered layout.
          return Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'order_type_selection'.tr,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Mulish',
                            color: Color(0xff0B1928),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ..._orderTypeSelectionButtons(controller),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
                child: Text(
                  'order_type_selection'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Mulish',
                    color: Color(0xff0B1928),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: 250,
                child: Container(
                  color: const Color(0xffF5F5F5),
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
                  child: Column(
                    children: _orderTypeSelectionButtons(controller),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'save_orders_section'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Mulish',
                    color: Color(0xff0B1928),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildSavedOrderCard(controller, index),
                  ),
                  childCount: controller.drafts.length,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _orderTypeSelectionButtons(PosPortraitController controller) {
    return [
      // Lieferung button
      _buildOrderTypeSelectionBtn(
        controller,
        label: 'delivery'.tr,
        icon: 'assets/images/delivery-icon.svg',
        value: 'Lieferzeit',
        enabled: true,
      ),
      const SizedBox(height: 16),
      // Abholung button
      _buildOrderTypeSelectionBtn(
        controller,
        label: 'pickup'.tr,
        icon: 'assets/images/pickup-icon.svg',
        value: 'Abholzeit',
        enabled: true,
      ),
      const SizedBox(height: 16),
      // Table ordering — disabled
      _buildOrderTypeSelectionBtn(
        controller,
        label: 'table_ordering'.tr,
        icon: 'assets/images/pickup-icon.svg', // ya koi table icon
        value: 'Table',
        enabled: false,
      ),
    ];
  }

  Widget _buildSavedOrderCard(PosPortraitController controller, int index) {
    final draft = controller.drafts[index];
    final List items = draft['cartItems'] as List;
    final Map details = draft['customerDetails'] as Map;
    final String customerName = details['name']?.toString().trim() ?? '';
    final int localOrderNumber =
        draft['localOrderNumber'] as int? ?? (index + 1);
    final String orderLabel = '${'order_label'.tr} - $localOrderNumber';
    final String itemWord = items.length == 1
        ? 'item_singular'.tr
        : 'item_plural'.tr;
    final String subtitle = customerName.isNotEmpty
        ? '$customerName / ${items.length} $itemWord'
        : '${items.length} $itemWord';
    double total = 0;
    for (var item in items) {
      total += (item['price'] as num) * (item['quantity'] as int);
    }

    return GestureDetector(
      onTap: () => controller.loadDraft(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bookmark_rounded,
              color: Color(0xff0C831F),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Mulish',
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${"currency".tr} ${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => controller.deleteDraft(index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  size: 25,
                  color: Colors.red.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelectionBtn(
    PosPortraitController controller, {
    required String label,
    required String icon,
    required String value,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? () {
              controller.selectedOrderType.value = value;
              // Slide animation ke saath screen switch
              controller.showOrderTypeSelection.value = false;
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xffF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? const Color(0xff0C831F) : Colors.grey.shade300,
            width: enabled ? 1.5 : 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              height: 24,
              width: 24,
              color: enabled ? const Color(0xff0C831F) : Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: enabled
                      ? const Color(0xff0B1928)
                      : Colors.grey.shade400,
                ),
              ),
            ),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'coming_soon'.tr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
            if (enabled)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xff0C831F),
              ),
          ],
        ),
      ),
    );
  }

  // ── 2. Selected order type bar (product screen ke top pe) ──────────────
  Widget _buildSelectedOrderTypeBar(PosPortraitController controller) {
    return Obx(() {
      final selected = controller.selectedOrderType.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setOrderType('Lieferzeit'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == 'Lieferzeit'
                        ? const Color(0xff0C831F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected == 'Lieferzeit'
                          ? const Color(0xff0C831F)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/delivery-icon.svg',
                        height: 14,
                        width: 14,
                        color: selected == 'Lieferzeit'
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'delivery'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: selected == 'Lieferzeit'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setOrderType('Abholzeit'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == 'Abholzeit'
                        ? const Color(0xff0C831F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected == 'Abholzeit'
                          ? const Color(0xff0C831F)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/pickup-icon.svg',
                        height: 14,
                        width: 14,
                        color: selected == 'Abholzeit'
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'pickup'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: selected == 'Abholzeit'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: controller.isRefreshing.value
                  ? null
                  : controller.refreshData,
              child: Container(
                padding: EdgeInsets.all(5),
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Color(0xffD5E6FF), width: 1),
                ),
                child: Center(
                  child: SvgPicture.asset('assets/images/refresh.svg'),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPortraitHeader(PosPortraitController controller) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => controller.resetToSelectionScreen(),
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: const Color(0xffF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: Color(0xff0B1928),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/mirch.png',
                height: 25,
                width: 25,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffDDEAFF), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 15, color: Colors.black),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.onSearchChanged,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        controller.clearSearch();
                        FocusScope.of(context).unfocus();
                      },
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Mulish',
                      ),
                      decoration: InputDecoration(
                        hintText: 'search_item'.tr,
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
                        child: const Icon(
                          Icons.clear,
                          size: 15,
                          color: Colors.grey,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: controller.isRefreshing.value
                  ? null
                  : controller.refreshData,
              child: Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.all(4),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xffE31E24),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Color(0xffE31E24),
                        size: 15,
                      ),
              ),
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
              itemCount: controller.categories.length, // ✅ filtered list
              itemBuilder: (context, index) {
                bool isSelected =
                    controller.selectedCategoryIndex.value == index;
                var category = controller.categories[index]; // ✅ CategoryData

                return GestureDetector(
                  onTap: () => controller.scrollToCategory(index),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffFAFCFF)
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: controller.getTrimmedImageUrl(
                                category.imageUrl,
                              ),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFamily: 'Mulish',
                              color: isSelected
                                  ? const Color(0xff0C831F)
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Obx(() {
              final idx = controller.selectedCategoryIndex.value;
              final maxIdx = controller.categories.length - 1;
              final safeIdx = idx.clamp(0, maxIdx < 0 ? 0 : maxIdx);
              return Positioned(
                right: 0,
                top: safeIdx * 80.0,
                child: Container(
                  width: 3,
                  height: 80,
                  color: const Color(0xffE31E24),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  // ─── ORDERS SECTION ────────────────────────────────────────────────────
  Widget _buildOrdersSection(
    PosPortraitController controller,
    BuildContext context,
  ) {
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
                    Image.asset(
                      'assets/images/mirch.png',
                      height: 22,
                      width: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'orders_title'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM, y').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Obx(
                      () => Text(
                        '${'total'.tr}: ${controller.orderStats['totalOrders']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => controller.loadOrders(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.refresh,
                          color: Color(0xffE31E24),
                          size: 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.syncLocalOrders(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.sync,
                          color: Color(0xffE31E24),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats row
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _orderStatChip(
                    '${'accepted'.tr} ${controller.orderStats['accepted']}',
                    Colors.green.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  _orderStatChip(
                    '${'decline'.tr} ${controller.orderStats['declined']}',
                    Colors.red.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  _orderStatChip(
                    '${'pickup'.tr} ${controller.orderStats['pickup']}',
                    Colors.blue.withOpacity(0.1),
                  ),
                  const SizedBox(width: 8),
                  _orderStatChip(
                    '${'delivery'.tr} ${controller.orderStats['delivery']}',
                    Colors.purple.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ),
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
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Mulish',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    PosPortraitController controller,
    BuildContext context,
  ) {
    return Obx(() {
      if (controller.isLoadingOrders.value) {
        return Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 120,
            height: 120,
          ),
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
              Lottie.asset(
                'assets/animations/empty.json',
                width: 120,
                height: 120,
              ),
              Text(
                'no_order'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  fontFamily: 'Mulish',
                ),
              ),
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

  Widget _buildOrderCard(
    PosPortraitController controller,
    Order order,
    bool isLocalOrder,
  ) {
    DateTime dateTime;
    try {
      dateTime = DateTime.parse(order.createdAt.toString());
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
        case 2:
          return const Color(0xffEBFFF4);
        case 3:
          return const Color(0xffFFEFEF);
        default:
          return Colors.white;
      }
    }

    Color borderColor() {
      if (order.source == 'pos') return const Color(0xffB8ABD1);
      switch (order.approvalStatus) {
        case 2:
          return const Color(0xffC3F2D9);
        case 3:
          return const Color(0xffFFD0D0);
        default:
          return Colors.grey.withOpacity(0.2);
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
                              ? 'pickup'.tr
                              : (order.shipping_address?.zip?.toString() ??
                                    guestZip),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        if (order.deliveryTime != null &&
                            order.deliveryTime!.isNotEmpty)
                          Text(
                            '${'time'.tr}: ${controller.extractTime(order.deliveryTime!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Mulish',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Mulish',
                      ),
                    ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'Mulish',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${'order_hash'.tr}${order.orderNumber ?? order.id ?? 'N/A'}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'Mulish'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${"currency".tr} ${controller.formatAmount(order.payment?.amount ?? 0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'Mulish',
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isLocalOrder
                          ? 'syncing'.tr
                          : controller.getApprovalStatusText(
                              order.approvalStatus,
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(width: 4),
                    isLocalOrder
                        ? const _SyncIcon()
                        : CircleAvatar(
                            radius: 10,
                            backgroundColor: controller.getStatusColor(
                              order.approvalStatus ?? 0,
                            ),
                            child: Icon(
                              controller.getStatusIcon(
                                order.approvalStatus ?? 0,
                              ),
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

  Widget _buildPortraitContent(
    PosPortraitController controller,
    BuildContext context,
  ) {
    return Obx(() {
      final filtered = controller.getFilteredCategories();
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
                    ? 'no_match'.tr
                    : 'no_categories_available'.tr,
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
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: displayCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = displayCategories[categoryIndex];
          return _buildCategorySection(controller, category);
        },
      );
    });
  }

  Widget _buildCategorySection(
    PosPortraitController controller,
    CategoryData category,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
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
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 5,
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
      bool isInCart = controller.cartItems.any(
        (item) => item['product_id'] == actualProduct?.id,
      );

      int totalQuantity = 0;
      if (isInCart) {
        controller.cartItems
            .where((item) => item['product_id'] == actualProduct?.id)
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
                  padding: const EdgeInsets.all(6),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                            '${"currency".tr}${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                              color: isInCart
                                  ? const Color(0xff0C831F)
                                  : const Color(0xff0B1928),
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

  Widget _buildDraggableFab(
    PosPortraitController controller,
    BuildContext ctx,
  ) {
    final screenSize = MediaQuery.of(ctx).size;
    final padding = MediaQuery.of(ctx).padding;
    final barHeight = Platform.isIOS ? 90.0 : 70.0;
    final bodyHeight = screenSize.height - padding.top - barHeight;

    // Lazy-init: default position above the cart button (bottom-right)
    _fabPosition ??= Offset(screenSize.width - 72, bodyHeight - 72);

    return Positioned(
      left: _fabPosition!.dx,
      top: _fabPosition!.dy,
      child: GestureDetector(
        onTap: () => _showAddCustomItemDialog(controller, ctx),
        onPanUpdate: (details) {
          setState(() {
            _fabPosition = Offset(
              (_fabPosition!.dx + details.delta.dx).clamp(
                0.0,
                screenSize.width - 56,
              ),
              (_fabPosition!.dy + details.delta.dy).clamp(0.0, bodyHeight - 56),
            );
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xffE31E24),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _showAddCustomItemDialog(
    PosPortraitController controller,
    BuildContext ctx,
  ) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'add_custom_item'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetCtx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xffF0F0F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'item_name_label'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Mulish'),
                    decoration: InputDecoration(
                      hintText: 'item_name_hint'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontFamily: 'Mulish',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
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
                  const SizedBox(height: 16),
                  Text(
                    'item_price_label'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 14, fontFamily: 'Mulish'),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontFamily: 'Mulish',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetCtx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xffEEEEEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'cancel'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Mulish',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final name = nameCtrl.text.trim();
                            final price =
                                double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                            if (name.isEmpty) return;
                            controller.addCustomItemToCart(name, price);
                            Navigator.pop(sheetCtx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xff0C831F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'add_item'.tr,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedOrdersScreen(PosPortraitController controller) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => controller.showSavedOrdersScreen.value = false,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffFBF9FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'saved_orders_title'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Mulish',
                  ),
                ),
                const Spacer(),
                Obx(
                  () => Text(
                    '${controller.drafts.length} ${controller.drafts.length == 1 ? 'draft_singular'.tr : 'draft_plural'.tr}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Mulish',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffEEEEEE)),
          // List
          Expanded(
            child: Obx(() {
              if (controller.drafts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'no_saved_orders'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Mulish',
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.drafts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final draft = controller.drafts[index];
                  final List items = draft['cartItems'] as List;
                  final Map details = draft['customerDetails'] as Map;
                  final String customerName =
                      details['name']?.toString().trim() ?? '';
                  final int localOrderNumber =
                      draft['localOrderNumber'] as int? ?? (index + 1);
                  final String orderLabel =
                      '${'order_label'.tr} - $localOrderNumber';
                  final String itemWord = items.length == 1
                      ? 'item_singular'.tr
                      : 'item_plural'.tr;
                  final String subtitle = customerName.isNotEmpty
                      ? '$customerName / ${items.length} $itemWord'
                      : '${items.length} $itemWord';
                  double total = 0;
                  for (var item in items) {
                    total += (item['price'] as num) * (item['quantity'] as int);
                  }

                  return GestureDetector(
                    onTap: () {
                      controller.loadDraft(index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffEEEEEE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            color: Color(0xff0C831F),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Mulish',
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${"currency".tr} ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.deleteDraft(index),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPosBottomBar(PosPortraitController controller) {
    final barHeight = Platform.isIOS ? 90.0 : 70.0;
    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          // ── Main bar ────────────────────────────────────────────────
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Order icon with live badge
                Obx(
                  () => _buildPosBarItem(
                    icon: 'assets/images/ic_order.svg',
                    label: 'order'.tr,
                    badge: app.appController.getPendingOrder,
                    onTap: () => widget.onNavigateToTab?.call(0),
                  ),
                ),
                // Search
                _buildPosBarItem(
                  icon: 'assets/images/search.svg',
                  label: 'search_label'.tr,
                  onTap: () => controller.showPosSearchBar.value = true,
                ),
                // Save Orders
                Obx(
                  () => _buildPosBarItem(
                    icon: 'assets/images/invoice.svg',
                    label: 'save_orders_section'.tr,
                    badge: controller.drafts.length,
                    onTap: () => controller.openSavedOrdersScreen(),
                  ),
                ),
                // Cart — becomes green checkout button when items in cart
                Obx(() {
                  final count = controller.totalItems.value;
                  final price = controller.totalPrice.value;
                  if (count > 0) {
                    return GestureDetector(
                      onTap: () => controller.showCheckout.value = true,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: Platform.isIOS ? 12 : 10,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xff0C831F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/cart.svg',
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${"currency".tr} ${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: -10,
                              right: -14,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return _buildPosBarItem(
                    icon: 'assets/images/cart.svg',
                    label: 'cart_label'.tr,
                    onTap: () {},
                  );
                }),
              ],
            ),
          ),
          // ── Search overlay (slides in horizontally over the bar) ─────
          Obx(() {
            final show = controller.showPosSearchBar.value;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: 0,
              left: show ? 0 : MediaQuery.of(context).size.width,
              right: 0,
              height: barHeight,
              child: AnimatedOpacity(
                opacity: show ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: Platform.isIOS ? 24 : 12,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/search.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xffE31E24),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          onChanged: controller.onSearchChanged,
                          autofocus: show,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            controller.clearSearch();
                            FocusScope.of(context).unfocus();
                          },
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Mulish',
                          ),
                          decoration: InputDecoration(
                            hintText: 'search_item'.tr,
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Mulish',
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          controller.clearSearch();
                          controller.showPosSearchBar.value = false;
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xffEEF0F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPosBarItem({
    required String icon,
    required String label,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  icon,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xff757B8F),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar(PosPortraitController controller) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          controller.showCheckout.value = true;
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff0C831F),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white,
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
                          '${controller.totalPrice.value.toStringAsFixed(2)} ${"currency".tr}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        Text(
                          '${'item_singular'.tr}: ${controller.totalItems.value}',
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
                Row(
                  children: [
                    Text(
                      'view_cart'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish',
                      ),
                    ),
                    const SizedBox(width: 8),
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
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.showCheckout.value = false,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: const Icon(Icons.arrow_back, size: 24),
                        ),
                      ),
                      _buildOrderTypeBtn(
                        controller,
                        'Lieferzeit',
                        'assets/images/delivery-icon.svg',
                      ),
                      const SizedBox(width: 8),
                      _buildOrderTypeBtn(
                        controller,
                        'Abholzeit',
                        'assets/images/pickup-icon.svg',
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => controller.showAddNoteDialog(context),
                        child: Obx(
                          () => Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: controller.orderNote.value.isNotEmpty
                                  ? const Color(0xff0C831F).withOpacity(0.1)
                                  : const Color(0xffF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/note.png',
                              height: 22,
                              width: 22,
                              color: controller.orderNote.value.isNotEmpty
                                  ? const Color(0xff0C831F)
                                  : const Color(0xff0B1928),
                            ),
                          ),
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
                        _buildCollapsibleSummary(context, controller),

                        const SizedBox(height: 16),
                        // Payment Method Section
                        _buildPaymentMethodSection(controller),

                        const SizedBox(height: 16),
                        // Customer Details Section
                        Obx(() {
                          if (controller.customerDetails.isEmpty) {
                            return _buildCustomerDetailsForm(
                              controller,
                              context,
                            );
                          } else {
                            return _buildCustomerDetailsDisplay(controller);
                          }
                        }),

                        const SizedBox(height: 16),

                        // Time Selection Section (Heute/Vorbestellen)
                        _buildTimeSelectionSection(controller, context),

                        const SizedBox(height: 16),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom Draft + Preview + Place Order Buttons
                Obx(() {
                  final bool hasItems = controller.cartItems.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Draft button
                        Expanded(
                          child: GestureDetector(
                            onTap: hasItems
                                ? () => controller.saveAsDraft()
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: hasItems
                                    ? const Color(0xff6C4AB6)
                                    : const Color(0xffB8ABD1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bookmark_outline_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'draft_singular'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Preview button
                        Expanded(
                          child: GestureDetector(
                            onTap: hasItems
                                ? () {
                                    controller.showPreview();
                                    Get.to(
                                      () => OrderPreviewScreen(
                                        controller: controller,
                                      ),
                                    );
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: hasItems
                                    ? const Color(0xffFF9800)
                                    : const Color(0xffFFCC80),
                                border: const Border.symmetric(
                                  vertical: BorderSide(
                                    color: Colors.white,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'preview_label'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Place Order button
                        Expanded(
                          child: GestureDetector(
                            onTap: hasItems
                                ? () => controller.placeOrder()
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: hasItems
                                    ? const Color(0xff0C831F)
                                    : const Color(0xffA5D6A7),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'place_order'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
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

  Widget _buildOrderTypeBtn(
    PosPortraitController controller,
    String type,
    String iconPath,
  ) {
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
                color: isSelected
                    ? const Color(0xff0C831F)
                    : Colors.grey.shade300,
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
                  type == 'Lieferzeit' ? 'delivery'.tr : 'pickup'.tr,
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
  Widget _buildCollapsibleSummary(
    BuildContext context,
    PosPortraitController controller,
  ) {
    return Obx(() {
      double subtotal = controller.calculateSubtotal();
      double discount = controller.calculateDiscount();
      double grandTotal = controller.calculateGrandTotal();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      Text(
                        'subtotal'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Text(
                        '${subtotal.toStringAsFixed(2)} ${"currency".tr}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Add Discount TextField
                  Row(
                    children: [
                      Text(
                        'add_discount'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                          color: Color(0xff00B10E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 70,
                        height: 34,
                        child: TextField(
                          controller: controller.discountTextController,
                          keyboardType: TextInputType.text,
                          textAlign: TextAlign.center,
                          onChanged: controller.onManualDiscountChanged,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mulish',
                            color: Color(0xff00B10E),
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Mulish',
                              color: Colors.grey.shade400,
                            ),
                            suffixText: '%',
                            suffixStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                              color: Color(0xff00B10E),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: Color(0xff00B10E),
                              ),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (discount > 0)
                        Text(
                          '-${discount.toStringAsFixed(2)} ${"currency".tr}',
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
                      Text(
                        'grand_total'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${grandTotal.toStringAsFixed(2)} ${"currency".tr}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => controller.isCartExpanded.value =
                                !controller.isCartExpanded.value,
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
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
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
                      return _buildCartItemRow(
                        context,
                        controller,
                        item,
                        index,
                      );
                    }),
                    if (controller.orderNote.value.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffFFE082)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.sticky_note_2_outlined,
                              size: 16,
                              color: Color(0xffF9A825),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.orderNote.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff5D4037),
                                ),
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
    });
  }

  Widget _buildCartItemRow(
    BuildContext context,
    PosPortraitController controller,
    Map<String, dynamic> item,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Remove button
          GestureDetector(
            onTap: () => controller.removeCartItem(index),
            child: const Icon(Icons.close, size: 20, color: Color(0xffE31E24)),
          ),

          const SizedBox(width: 8),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item["quantity"]} ×',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 5),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.33,
                      child: Text(
                        '${item['name']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (((item["base_price"] ?? item["price"]) as num) > 0)
                      Text(
                        '[${"currency".tr}${((item["base_price"] ?? item["price"]) as num).toStringAsFixed(2)}]',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => controller.editItemNote(
                        index: index,
                        initial: item['item_note'] ?? '',
                        onSave: (v) => controller.updateItemNote(index, v),
                      ),
                      child: Image.asset(
                        'assets/images/note.png',
                        height: 18,
                        width: 18,
                        color:
                            item['item_note'] != null &&
                                item['item_note'].toString().isNotEmpty
                            ? const Color(0xff0C831F)
                            : const Color(0xff0B1928),
                      ),
                    ),
                  ],
                ),
                // Variant
                if (item['size'] != null && item['size'].toString().isNotEmpty)
                  Text(
                    ((item["variant_price"] ?? 0) as num) > 0
                        ? '● ${item["size"]}    [${"currency".tr}${((item["variant_price"] ?? 0) as num).toStringAsFixed(2)}]'
                        : '● ${item["size"]}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                // // Toppings
                if (item['extras'] != null &&
                    item['extras'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${item['extras']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Note
                if (item['item_note'] != null &&
                    item['item_note'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${'note'.tr}: ${item["item_note"]}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Quantity Controls
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => controller.decrementQuantity(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          //border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: Text(
                          '${item["quantity"]}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.incrementQuantity(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          //border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(child: const Icon(Icons.add, size: 16)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Text(
                '${"currency".tr} ${((item["quantity"] as int) * (item["price"] as num)).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(width: 6),

          // Total Price
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsForm(
    PosPortraitController controller,
    BuildContext context,
  ) {
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
              Text(
                'customer_details'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // _buildTextField(controller.nameController, 'Ihre Name *', context),
          _buildTextField(
            controller.nameController,
            'your_name'.tr,
            context,
            focusNode: controller.nameFocusNode,
            nextFocusNode: controller.phoneFocusNode,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          // _buildTextField(controller.phoneController, 'Ihre Telefonnummer *', context),
          _buildTextField(
            controller.phoneController,
            'your_phone'.tr,
            context,
            focusNode: controller.phoneFocusNode,
            nextFocusNode: controller.addressFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 12),
          // _buildTextField(controller.addressController, 'Straße und Hausnummer *', context),
          _buildTextField(
            controller.addressController,
            'street_address'.tr,
            context,
            focusNode: controller.addressFocusNode,
            nextFocusNode: null,
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              if (controller.selectedOrderType.value == 'Lieferzeit') {
                FocusScope.of(context).requestFocus(controller.regionFocusNode);
              } else {
                FocusScope.of(context).requestFocus(controller.emailFocusNode);
              }
            },
          ),

          if (controller.selectedOrderType.value == 'Lieferzeit') ...[
            const SizedBox(height: 12),
            _buildTextField(
              controller.regionController,
              'postcode'.tr,
              context,
              focusNode: controller.regionFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              suffixIcon: GestureDetector(
                onTap: () => controller.showPostcodeDialog.value = true,
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xff0C831F),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          //  _buildTextField(controller.emailController, 'Ihre E-Mail', context),
          _buildTextField(
            controller.emailController,
            'your_email'.tr,
            context,
            focusNode: controller.emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    BuildContext context, {
    Widget? suffixIcon,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool readOnly = false,
    Function(String)? onFieldSubmitted,
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
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType ?? TextInputType.text,
          textInputAction: textInputAction ?? TextInputAction.next,
          onSubmitted: (value) {
            if (onFieldSubmitted != null) {
              onFieldSubmitted(value);
            } else if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: label.replaceAll('*', '').trim(),
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontFamily: 'Mulish',
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
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
                  SvgPicture.asset(
                    'assets/images/user.svg',
                    height: 16,
                    width: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'customer_details'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: controller.editCustomerDetails,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Image.asset(
                    'assets/images/note.png',
                    height: 18,
                    width: 18,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xffE6E1EE)),
          _buildDetailRow(
            'your_name'.tr,
            controller.customerDetails['name'] ?? '',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'your_phone'.tr,
            controller.customerDetails['phone'] ?? '',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'your_email'.tr,
            controller.customerDetails['email'] ?? '',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'address'.tr,
            controller.customerDetails['address'] ?? '',
          ),
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
            style: const TextStyle(fontSize: 12, fontFamily: 'Mulish'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(PosPortraitController controller) {
    return Obx(() {
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
                const Icon(Icons.payment, size: 18, color: Color(0xff0B1928)),
                const SizedBox(width: 8),
                Text(
                  'payment_method'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Mulish',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedPaymentMethod.value = 'cash',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: controller.selectedPaymentMethod.value == 'cash'
                            ? const Color(0xff0C831F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              controller.selectedPaymentMethod.value == 'cash'
                              ? const Color(0xff0C831F)
                              : Colors.grey.shade300,
                          width:
                              controller.selectedPaymentMethod.value == 'cash'
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 20,
                            color:
                                controller.selectedPaymentMethod.value == 'cash'
                                ? Colors.white
                                : const Color(0xff0B1928),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'cash'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                              color:
                                  controller.selectedPaymentMethod.value ==
                                      'cash'
                                  ? Colors.white
                                  : const Color(0xff0B1928),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        controller.selectedPaymentMethod.value = 'card',
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: controller.selectedPaymentMethod.value == 'card'
                            ? const Color(0xff0C831F)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              controller.selectedPaymentMethod.value == 'card'
                              ? const Color(0xff0C831F)
                              : Colors.grey.shade300,
                          width:
                              controller.selectedPaymentMethod.value == 'card'
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.credit_card,
                            size: 20,
                            color:
                                controller.selectedPaymentMethod.value == 'card'
                                ? Colors.white
                                : const Color(0xff0B1928),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'card'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                              color:
                                  controller.selectedPaymentMethod.value ==
                                      'card'
                                  ? Colors.white
                                  : const Color(0xff0B1928),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimeSelectionSection(
    PosPortraitController controller,
    BuildContext context,
  ) {
    return Obx(() {
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
            // ── Heute ───────────────────────────────────────────────
            if (controller.isStoreOpen.value) ...[
              GestureDetector(
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
                    Text(
                      'today_option'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ],
                ),
              ),

              // Heute timeslots — sofort + all future slots
              if (controller.isHeuteSelected.value) ...[
                const SizedBox(height: 12),
                // Sofort label — always selected when Heute is active
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff0C831F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xff0C831F)),
                  ),
                  child: Text(
                    'immediately'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.white,
                    ),
                  ),
                ),
                // Time slot chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.sofortTimeSlots.map((slot) {
                    final time = slot['time']!;
                    final isSelected =
                        controller.selectedTimeSlot.value == time;
                    return GestureDetector(
                      onTap: () => controller.selectTimeSlot(time, 'heute'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff0C831F)
                              : const Color(0xffF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff0C831F)
                                : Colors.grey.shade300,
                          ),
                        ),
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
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),
            ],
            // ── Vorbestellen ─────────────────────────────────────────
            GestureDetector(
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
                  Text(
                    'preorder'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ),

            if (controller.isVorbestellenSelected.value) ...[
              const SizedBox(height: 12),
              // Date picker
              GestureDetector(
                onTap: () => controller.selectVorbestellenDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFBF9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDate.value != null
                            ? DateFormat(
                                'dd.MM.yyyy',
                              ).format(controller.selectedDate.value!)
                            : 'select_date'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xffE31E24),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Time slots — only show after date selected
              if (controller.selectedDate.value != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.sofortTimeSlots.map((slot) {
                    final time = slot['time']!;
                    final isSelected =
                        controller.selectedTimeSlot.value == time;
                    return GestureDetector(
                      onTap: () =>
                          controller.selectTimeSlot(time, 'vorbestellen'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff0C831F)
                              : const Color(0xffF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff0C831F)
                                : Colors.grey.shade300,
                          ),
                        ),
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
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      );
    });
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
    double base =
        double.tryParse(
          controller.selectedProduct.value!.price?.toString() ?? '0',
        ) ??
        0.0;
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
      if (!controller.showVariantDialog.value ||
          controller.selectedProduct.value == null) {
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
                                border: Border.all(
                                  color: const Color(0xffE1E8F1),
                                ),
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
                              Text(
                                'choose_variant'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Mulish',
                                  color: Color(0xff475569),
                                ),
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 2.4,
                                    ),
                                itemCount: product.variants!.length,
                                itemBuilder: (context, i) {
                                  final variant = product.variants![i];
                                  return Obx(() {
                                    final isSelected =
                                        controller.selectedVariant.value?.id ==
                                        variant.id;
                                    return GestureDetector(
                                      onTap: () =>
                                          controller.selectVariant(variant),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected
                                                ? _green
                                                : _border,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: isSelected
                                              ? _lightGreen
                                              : Colors.white,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    variant.name ?? '',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily: 'Mulish',
                                                      color: isSelected
                                                          ? _green
                                                          : const Color(
                                                              0xff475569,
                                                            ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: _green,
                                                    size: 16,
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${"currency".tr}${(variant.price ?? 0).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Mulish',
                                                color: isSelected
                                                    ? _green
                                                    : const Color(0xff475569),
                                              ),
                                            ),
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
                              final selVariant =
                                  controller.selectedVariant.value;
                              if (selVariant == null)
                                return const SizedBox.shrink();
                              final isExpanded =
                                  controller.expandedVariantId.value ==
                                  selVariant.id;
                              if (!isExpanded) return const SizedBox.shrink();
                              final groups =
                                  selVariant.enrichedToppingGroups ?? [];
                              if (groups.isEmpty)
                                return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: groups.map((group) {
                                  final bool isRequired =
                                      group.isRequired == true;
                                  final int minSel = group.minSelect ?? 0;
                                  final int maxSel = group.maxSelect ?? 0;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Group header
                                      Row(
                                        children: [
                                          Text(
                                            group.name?.toUpperCase() ??
                                                'topping'.tr.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Mulish',
                                              color: Color(0xff475569),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          if (isRequired)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _green.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'required_label'.tr,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: _green,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Mulish',
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (isRequired && minSel > 0) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${'select_label'.tr} $minSel${maxSel > minSel ? ' - $maxSel' : ''} ${'items_unit'.tr}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Mulish',
                                          ),
                                        ),
                                      ],
                                      // Group error
                                      Obx(() {
                                        final err = controller
                                            .variantGroupErrors[group.id ?? 0];
                                        if (err == null)
                                          return const SizedBox.shrink();
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.shade200,
                                            ),
                                          ),
                                          child: Text(
                                            err,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12,
                                              fontFamily: 'Mulish',
                                            ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 10),
                                      // Topping items
                                      ...(group.toppings ?? []).map((topping) {
                                        return Obx(() {
                                          final isToppingSelected =
                                              controller
                                                  .selectedToppingsMap[selVariant
                                                      .id]
                                                  ?.contains(topping.id) ??
                                              false;
                                          return GestureDetector(
                                            onTap: () =>
                                                controller.toggleVariantTopping(
                                                  selVariant.id!,
                                                  topping.id!,
                                                  groupId: group.id,
                                                  maxSelect: maxSel > 0
                                                      ? maxSel
                                                      : null,
                                                ),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isToppingSelected
                                                      ? _green
                                                      : _border,
                                                  width: isToppingSelected
                                                      ? 1.5
                                                      : 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: isToppingSelected
                                                    ? _lightGreen
                                                    : Colors.white,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      topping.name ?? '',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Mulish',
                                                        fontWeight:
                                                            isToppingSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                        color: const Color(
                                                          0xff475569,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '${"currency".tr}${(topping.price ?? 0).toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Mulish',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isToppingSelected
                                                          ? _green
                                                          : const Color(
                                                              0xff475569,
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isToppingSelected
                                                          ? _green
                                                          : Colors.transparent,
                                                      border: Border.all(
                                                        color: isToppingSelected
                                                            ? _green
                                                            : Colors
                                                                  .grey
                                                                  .shade400,
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: isToppingSelected
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 13,
                                                          )
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
                            Text(
                              'special_request'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Mulish',
                                color: Color(0xff475569),
                              ),
                            ),
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
                                onSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Mulish',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'special_request_hint'.tr,
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
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
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Obx(() {
                        final hasVariant =
                            controller.selectedVariant.value != null;
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
                                    ? '${'add_to_cart_label'.tr}  •  ${"currency".tr}${total.toStringAsFixed(2)}'
                                    : 'please_select_variant'.tr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Mulish',
                                  color: Colors.white,
                                ),
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
                          Text(
                            'select_postcode'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                controller.showPostcodeDialog.value = false,
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
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'no_postcodes_available'.tr,
                                  style: const TextStyle(
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
                                final isSelected =
                                    controller.selectedPostcode.value?.id ==
                                    postcode.id;
                                return GestureDetector(
                                  onTap: () =>
                                      controller.selectPostcode(postcode),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          postcode.postcode ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontFamily: 'Mulish',
                                            color: isSelected
                                                ? const Color(0xff0C831F)
                                                : Colors.black,
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
                Text(
                  'select_delivery_time'.tr,
                  style: const TextStyle(
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
                if (controller.isStoreOpen.value)
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
                          'today_option'.tr,
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
                if (controller.isStoreOpen.value) const SizedBox(width: 8),
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
                        'preorder'.tr,
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
      if (!controller.isStoreOpen.value) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_mall_directory_outlined,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                'store_closed_currently'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'use_preorder_hint'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Mulish',
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.sofortTimeSlots.isEmpty) {
        return Center(
          child: Text(
            'no_time_slots_available'.tr,
            style: const TextStyle(
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
                        ? DateFormat(
                            'dd.MM.yyyy',
                          ).format(controller.selectedVorbestellenDate.value!)
                        : 'select_date'.tr,
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

class _SyncIconState extends State<_SyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
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

class OrderPreviewScreen extends StatelessWidget {
  final PosPortraitController controller;

  const OrderPreviewScreen({super.key, required this.controller});

  String _fmt(double amount) => amount.toStringAsFixed(2);

  Widget _divider() {
    const style = TextStyle(
      fontSize: 14,
      color: Colors.grey,
      fontFamily: 'Mulish',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final charWidth = (TextPainter(
          text: const TextSpan(text: '=', style: style),
          textDirection: ui.TextDirection.ltr,
        )..layout()).width;
        final count = (constraints.maxWidth / charWidth).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '=' * count,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: style,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = controller.previewCustomerDetails;
    final items = controller.cartItems;
    final subtotal = controller.calculateSubtotal();
    final discount = controller.calculateDiscount();
    final grandTotal = controller.calculateGrandTotal();
    final taxBreakdown = controller.calculateTaxBreakdown();
    final orderType = controller.selectedOrderType.value;
    final paymentMethod = controller.selectedPaymentMethod.value;
    final note = controller.orderNote.value;
    final storeName = controller.storeName;

    String timeDisplay = '';
    if (controller.selectedTimeSlot.value == 'sofort') {
      timeDisplay = 'immediately'.tr;
    } else if (controller.selectedTimeSlot.value.isNotEmpty) {
      if (controller.selectedDate.value != null) {
        timeDisplay =
            '${DateFormat('dd.MM.yyyy').format(controller.selectedDate.value!)} ${controller.selectedTimeSlot.value}';
      } else {
        timeDisplay =
            '${'today_option'.tr} ${controller.selectedTimeSlot.value}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Store header ──────────────────────────────────────
                  if (storeName.isNotEmpty) ...[
                    Center(
                      child: Text(
                        storeName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  _divider(),

                  // ── Order type + Date ─────────────────────────────────
                  Center(
                    child: Text(
                      (orderType == 'Lieferzeit' ? 'delivery'.tr : 'pickup'.tr)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${'date'.tr}: ${DateFormat('dd-MM-yyyy  HH:mm').format(DateTime.now())}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  if (timeDisplay.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${orderType == 'Lieferzeit' ? 'delivery_time'.tr : 'collection'.tr}: $timeDisplay',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ),
                  ],

                  _divider(),

                  // ── Customer block ────────────────────────────────────
                  if (details['phone']?.isNotEmpty == true)
                    _infoRow(details['phone']!),
                  if (details['name']?.isNotEmpty == true)
                    _infoRow(details['name']!),
                  if (orderType == 'Lieferzeit' &&
                      details['address']?.isNotEmpty == true)
                    _infoRow(details['address']!),
                  if (details['region']?.isNotEmpty == true)
                    _infoRow(details['region']!),
                  if (details['email']?.isNotEmpty == true)
                    _infoRow(details['email']!),

                  _divider(),

                  // ── Items ─────────────────────────────────────────────
                  ...items.map((item) {
                    final double itemTotal =
                        (item['price'] as num).toDouble() *
                        (item['quantity'] as int);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['quantity']}x ${item['name']}'
                                  '${(item['size'] == null || item['size'].toString().isEmpty) ? '  [${"currency".tr}${(item['price'] as num).toStringAsFixed(2)}]' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                              ),
                              Text(
                                '${"currency".tr} ${_fmt(itemTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ],
                          ),
                          if (item['size'] != null &&
                              item['size'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Text(
                                '${item['quantity']} × ${item['size']}  [${"currency".tr}${(item['price'] as num).toStringAsFixed(2)}]',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          if (item['extras'] != null &&
                              item['extras'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: Text(
                                '+ ${item['extras']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          if (item['item_note'] != null &&
                              item['item_note'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 3),
                              child: Text(
                                '${'note'.tr}: ${item['item_note']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Color(0xff0C831F),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  // ── Order note ────────────────────────────────────────
                  if (note.isNotEmpty) ...[
                    _divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${'note'.tr}:  ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'Mulish',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  _divider(),

                  // ── Totals ────────────────────────────────────────────
                  _totalsRow(
                    'subtotal'.tr,
                    '${"currency".tr} ${_fmt(subtotal)}',
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 2),
                    _totalsRow(
                      '${'discount'.tr} (${controller.manualDiscountPercent.value.toStringAsFixed(0)}%)',
                      '-${"currency".tr} ${_fmt(discount)}',
                      valueColor: const Color(0xff00B10E),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(height: 0.5, color: Colors.grey),
                  const SizedBox(height: 4),
                  _totalsRow(
                    ('grand_total'.tr).toUpperCase(),
                    '${"currency".tr} ${_fmt(grandTotal)}',
                    bold: true,
                  ),

                  _divider(),

                  // ── Payment ───────────────────────────────────────────
                  Text(
                    '${'payment_label'.tr}: ${paymentMethod == 'cash' ? 'cash'.tr : 'card'.tr}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                    ),
                  ),

                  // ── Tax table ─────────────────────────────────────────
                  if (taxBreakdown.isNotEmpty) ...[
                    _divider(),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'vat_rate'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'gross'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'net'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'vat'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...taxBreakdown.map(
                      (tax) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${(tax['tax_rate'] ?? 0).toStringAsFixed(0)} %',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Mulish',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _fmt(tax['brutto'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _fmt(tax['netto'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _fmt(tax['tax_amount'] ?? 0),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Mulish',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  _divider(),

                  // ── Footer ────────────────────────────────────────────
                  Center(
                    child: Text(
                      'information_label'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'allergy_notice'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Mulish',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Red circle close button (top-right) ───────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Mulish',
      ),
    ),
  );

  Widget _totalsRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontFamily: 'Mulish',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
