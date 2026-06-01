import 'dart:async';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../constants/app_color.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/order_model.dart';
import '../../utils/my_application.dart';
import '../Order/OrderDetailEnglish.dart';
import '../home_screen.dart';
import 'pos_controller.dart';
import 'pos_portrait.dart' show PosPortrait;

class ResponsivePos extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const ResponsivePos({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    // Landscape disabled for now — always portrait
    return PosPortrait(onNavigateToTab: onNavigateToTab);
  }
}

class PosLandscape extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const PosLandscape({super.key, this.onNavigateToTab});

  @override
  State<PosLandscape> createState() => _PosLandscapeState();
}

class _PosLandscapeState extends State<PosLandscape> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PosController controller;
  late AnimationController _syncRotationController;
  late Animation<double> _syncRotationAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PosController(), tag: 'pos_controller');
    _syncRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _syncRotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _syncRotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _syncRotationController.dispose();
    // ✅ Add a check before deleting controller
    if (Get.isRegistered<PosController>(tag: 'pos_controller')) {
      try {
        Get.delete<PosController>(tag: 'pos_controller', force: true);
      } catch (e) {
        print('⚠️ Error disposing PosController: $e');
      }
    }

    // ✅ Call super.dispose() last
    super.dispose();
  }

  double _getScaleFactor(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Base width: 1024px (standard iPad landscape)
    // Scale factor ranges from 0.7 (small) to 1.5 (very large)
    if (width < 900) return 0.75;
    if (width < 1100) return 0.9;
    if (width < 1300) return 1.0;
    if (width < 1500) return 1.15;
    if (width < 1800) return 1.3;
    return 1.5;
  }

  double _responsive(BuildContext context, double baseSize) {
    return baseSize * _getScaleFactor(context);
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 900) return 3;
    if (width < 1100) return 4;
    if (width < 1400) return 5;
    if (width < 1700) return 6;
    return 7;
  }

  void _openTab(int index) {
    print("🎯 POS: Navigating to tab $index");

    // ✅ Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    // ✅ Set orientation based on target tab
    if (index == 3) {
      // Staying on POS - maintain landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Going to other tabs - set portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // ✅ Wait for drawer to close and orientation to set
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // ✅ Check if we're on HomeScreen
      bool isOnHomeScreen = Get.currentRoute == '/HomeScreen' ||
          Get.currentRoute == '/' ||
          Get.currentRoute.isEmpty;

      if (isOnHomeScreen && widget.onNavigateToTab != null) {
        print("✅ Using onNavigateToTab callback");
        // ✅ Use callback to switch tabs within existing HomeScreen
        widget.onNavigateToTab!(index);
      } else {
        print("🔄 Navigating to HomeScreen with initialTab: $index");
        // ✅ Navigate to HomeScreen with initialTab
        Get.offAll(
              () => const HomeScreen(),
          arguments: {'initialTab': index},
          transition: Transition.noTransition,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
          // onWillPop: () async {
          //   await Future.delayed(const Duration(milliseconds: 150));
          //   return true;
          // },
        onWillPop: () async {
          if (controller.showOrderOverlay.value) {
            controller.hideOrderOverlay();
            return false;
          }
          return true;
        },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: CustomDrawer(onSelectTab: _openTab),
            backgroundColor: const Color(0xffFBF9FF),
            body:  Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: _responsive(context, 12)),
                    child: Row(
                      children: [
                        // _buildSidebar(controller, context),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(_responsive(context, 8)),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _buildProductsSection(controller, context),),
                                SizedBox(width: _responsive(context, 10)),
                                Expanded(
                                  flex: 3,
                                  child: _buildCartSection(controller, context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildVariantDialog(controller, context),
                  _buildPostcodeDialog(controller, context),
                  //_buildTimeBottomSheet(controller, context),
                ]),
          ));
  }

  Widget _buildSidebar(PosController controller, BuildContext context) {
    return Stack(
      children: [
        Container(
          width: _responsive(context, 60),
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(height: _responsive(context, 20)),
              Container(
                width: _responsive(context, 50),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsive(context, 12)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(_responsive(context, 5)),
                        padding: EdgeInsets.all(_responsive(context, 5)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(_responsive(
                              context, 7)),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/mirch.png',
                            width: _responsive(context, 35),
                            height: _responsive(context, 35),
                          ),
                        ),
                      ),
                      SizedBox(height: _responsive(context, 50)),
                      _buildSidebarItem(
                          Icons.shopping_bag_outlined, false, context),
                      SizedBox(height: _responsive(context, 20)),
                      _buildSidebarItem(
                          Icons.bar_chart_outlined, false, context),
                      SizedBox(height: _responsive(context, 20)),
                      _buildSidebarItem(
                          Icons.settings_outlined, false, context),
                      SizedBox(height: _responsive(context, 10)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: _responsive(context, 20)),
                child: GestureDetector(
                  onTap: () {
                    controller.showLogoutDialog(Get.context!);
                  },
                  child: Container(
                    width: _responsive(context, 45),
                    height: _responsive(context, 45),
                    decoration: BoxDecoration(
                      color: const Color(0xffE31E24),
                      borderRadius: BorderRadius.circular(
                          _responsive(context, 8)),
                    ),
                    child: Icon(
                      Icons.power_settings_new,
                      color: Colors.white,
                      size: _responsive(context, 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: _responsive(context, 75),
          right: 0,
          left: 0,
          child: Container(
            height: _responsive(context, 45),
            width: _responsive(context, 49),
            margin: EdgeInsets.only(left: _responsive(context, 10)),
            padding: EdgeInsets.only(right: _responsive(context, 10)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_responsive(context, 12)),
                bottomLeft: Radius.circular(_responsive(context, 12)),
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/plus.png',
                height: _responsive(context, 20),
                width: _responsive(context, 20),
                color: const Color(0xff0B1928),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, bool isActive, BuildContext context) {
    return Container(
      width: _responsive(context, 45),
      height: _responsive(context, 45),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xffE31E24) : Colors.transparent,
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
      ),
      child: Icon(
        icon,
        color: const Color(0xff0B1928),
        size: _responsive(context, 24),
      ),
    );
  }

  Widget _buildProductsSection(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.showOrderOverlay.value) {
        return _buildOrdersSection(controller, context);
      }

      return Column(
        children: [
          const SizedBox(height: 5),
          _buildHeader(controller, context),
          SizedBox(height: _responsive(context, 20)),
          _buildCategoryTabs(controller, context),

          Expanded(
            child: Obx(() {
              // If searching, show filtered products in a grid
              if (controller.searchQuery.value.isNotEmpty) {
                return _buildSearchResults(controller, context);
              }

              // Normal category-based view
              List<int> categoriesToShow = controller.visibleCategories
                  .toList();

              if (categoriesToShow.isEmpty) {
                return Center(
                  child: Text(
                    'No categories to show',
                    style: TextStyle(fontSize: _responsive(context, 14)),
                  ),
                );
              }

              return ScrollablePositionedList.builder(
                itemScrollController: controller.landscapeProductScrollController,
                itemPositionsListener: controller.landscapeProductPositionsListener,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                addSemanticIndexes: false,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.1,
                  top: _responsive(context, 8),
                  left: _responsive(context, 4),
                  right: _responsive(context, 4),
                ),
                itemCount: categoriesToShow.length,
                itemBuilder: (context, visibleIndex) {
                  int categoryIndex = categoriesToShow[visibleIndex];
                  if (categoryIndex >= controller.productCategoryList.length) {
                    return const SizedBox.shrink();
                  }

                  var category = controller.productCategoryList[categoryIndex];
                  var categoryProducts = controller.productList.where((p) =>
                  p.categoryId == category.id && (p.isActive ?? false)).toList();

                  if (categoryProducts.isEmpty) return const SizedBox.shrink();

                  return Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsive(context, 8),
                            vertical: _responsive(context, 12),
                          ),
                          child: Text(
                            category.name ?? '',
                            style: TextStyle(
                              fontSize: _responsive(context, 22),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          cacheExtent: 500,
                          addAutomaticKeepAlives: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            crossAxisSpacing: _responsive(context, 10),
                            mainAxisSpacing: _responsive(context, 10),
                            childAspectRatio: 1.3,
                          ),
                          itemCount: categoryProducts.length,
                          itemBuilder: (context, index) {
                            var product = categoryProducts[index];
                            return _buildProductCard(
                                controller, product, context);
                          },
                        ),
                        SizedBox(height: _responsive(context, 20)),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildSearchResults(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: _responsive(context, 60),
                color: Colors.grey.shade400,
              ),
              SizedBox(height: _responsive(context, 16)),
              Text(
                'No products found',
                style: TextStyle(
                  fontSize: _responsive(context, 18),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: _responsive(context, 8)),
              Text(
                'Try searching with different keywords',
                style: TextStyle(
                  fontSize: _responsive(context, 14),
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.all(_responsive(context, 8)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: _responsive(context, 10),
          mainAxisSpacing: _responsive(context, 10),
          childAspectRatio: 1.4,
        ),
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          var product = controller.filteredProducts[index];
          return _buildProductCard(controller, product, context);
        },
      );
    });
  }

  Widget _buildProductCard(PosController controller, GetStoreProducts product,
      BuildContext context)
  {
    return RepaintBoundary(
      child: Obx(() {
        int cartIndex = controller.cartItems.indexWhere(
                (item) => item['name'] == product.name);
        bool isInCart = cartIndex != -1;
        int quantity = isInCart
            ? controller.cartItems[cartIndex]['quantity']
            : 0;

        return GestureDetector(
          onTap: () {
            controller.showProductVariantDialog(product);
          },
          child: Container(
            padding: EdgeInsets.all(_responsive(context, 8)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_responsive(context, 8)),
              color: Colors.white,
              border: Border.all(
                color: isInCart
                    ? AppColor.borderGreen
                    : Color(0xff9B92AAFF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(left: _responsive(context, 4)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? '',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w600,
                      fontSize: _responsive(context, 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: isInCart
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.end,
                    children: [
                      if (isInCart)
                        Container(
                          width: _responsive(context, 24),
                          height: _responsive(context, 24),
                          decoration: const BoxDecoration(
                            color: AppColor.borderGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 15),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        '${double
                            .tryParse(product.price?.toString() ?? '0')
                            ?.toStringAsFixed(2) ?? '0.00'} €',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: _responsive(context, 18),
                          color: isInCart ? AppColor.borderGreen : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(PosController controller, BuildContext context) {
    return Stack(
        children: [
          Container(
            color: Colors.white,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9)
                  ),
                  child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          child: Image.asset(
                            'assets/images/mirch.png',
                            height: 25,
                            width: 25,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: _responsive(context, 12)),
                          height: _responsive(context, 40),
                          width: _responsive(context, 300),
                          padding: EdgeInsets.symmetric(
                              horizontal: _responsive(context, 8)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                _responsive(context, 5)),
                            color: const Color(0xffFBF9FF),
                          ),
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: controller.filterProducts,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(bottom: 5),
                              hintText: 'Search Item name or ID',
                              hintStyle: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w300,
                                fontSize: _responsive(context, 14),
                                fontStyle: FontStyle.italic,
                              ),
                              border: InputBorder.none,
                              suffixIcon: Obx(() =>
                                controller.searchQuery.value.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          controller.searchController.clear();
                                          controller.filterProducts('');
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: _responsive(context, 16),
                                          color: Colors.grey.shade600,
                                        ),
                                      )
                                    : Padding(
                                        padding: EdgeInsets.all(_responsive(context, 8)),
                                        child: Image.asset(
                                          'assets/images/search.png',
                                          height: _responsive(context, 8),
                                          width: _responsive(context, 8),
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: _responsive(context, 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5,),
                        InkWell(
                          onTap: () {
                            controller.showOrdersOverlay();
                            // if (widget.onNavigateToTab != null) {
                            //   widget.onNavigateToTab!(0);
                            // }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SvgPicture.asset(
                                'assets/images/order-icon.svg',
                                height: 20,
                                width: 20,
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child:Obx(() {
                                  return controller.pendingOrdersCount.value > 0
                                      ? Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xffE31E24),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${controller.pendingOrdersCount.value}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Mulish',
                                        ),
                                      ),
                                    ),
                                  )
                                      : const SizedBox.shrink();
                                }),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.07,),
                        // Row(
                        //   children: [
                        //     Image.asset(
                        //       'assets/images/german.png',
                        //       height: _responsive(context, 25),
                        //       width: _responsive(context, 25),
                        //     ),
                        //     SizedBox(width: _responsive(context, 5)),
                        //     Text(
                        //       'GER',
                        //       style: TextStyle(
                        //         fontSize: _responsive(context, 12),
                        //         fontWeight: FontWeight.w700,
                        //         fontFamily: 'Mulish',
                        //         color: const Color(0xff232121),
                        //       ),
                        //     ),
                        //     const Icon(Icons.arrow_drop_down)
                        //   ],
                        // ),
                      ]
                  ),
                ),
                Obx(() =>
                    GestureDetector(
                      onTap: controller.isRefreshing.value
                          ? null
                          : controller.refreshData,
                      child: Container(
                       // height: 60,
                        padding: EdgeInsets.all(_responsive(context, 10)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(_responsive(context, 5)),
                        ),
                        child: controller.isRefreshing.value
                            ? SizedBox(
                          width: _responsive(context, 20),
                          height: _responsive(context, 20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 1,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xffE31E24)),
                          ),
                        )
                            : Icon(
                          Icons.refresh,
                          color: const Color(0xffE31E24),
                          size: _responsive(context, 30),
                        ),
                      ),
                    )
                ),
                GestureDetector(
                  onTap: () {
                    Get.offAll(() => const HomeScreen());
                  },
                  child: Container(
                    height: 60,
                    padding: EdgeInsets.all(_responsive(context, 12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          _responsive(context, 9)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: _responsive(context, 20),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.18,
            top: 10,
            child: Container(
              height: _responsive(context, 71),
              width: _responsive(context, 55),
              margin: const EdgeInsets.all(5),
              // padding: EdgeInsets.only(right: _responsive(context, 10)),
              decoration: BoxDecoration(
                color: const Color(0xffFBF9FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_responsive(context, 12)),
                  topRight: Radius.circular(_responsive(context, 12)),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/plus.png',
                  height: _responsive(context, 20),
                  width: _responsive(context, 20),
                  color: const Color(0xff0B1928),
                ),
              ),
            ),
          )
        ]);
  }

  Widget _buildCategoryTabs(PosController controller, BuildContext context) {
    return SizedBox(
      height: _responsive(context, 115),
      child: Obx(() =>
          ListView.builder(
            controller: controller.landscapeCategoryScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: controller.productCategoryList.length,
            itemBuilder: (context, index) {
              var category = controller.productCategoryList[index];
              return Obx(() {
                bool isSelected = controller.selectedCategoryIndex.value ==
                    index;

                return GestureDetector(
                  onTap: () {
                    controller.selectCategory(index);
                  },
                  child: Container(
                    width: _responsive(context, 116),
                    height: _responsive(context, 80),
                    margin: EdgeInsets.only(right: _responsive(context, 5)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_responsive(
                          context, 8)),
                      border: Border.all(
                        color: isSelected ? AppColor.borderGreen : const Color(
                            0xffCFC1ED),
                        width: 1,
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: controller.getTrimmedImageUrl(
                                  category.imageUrl),
                              height: _responsive(context, 55),
                              width: _responsive(context, 55),
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.restaurant,
                                      size: _responsive(context, 20)),
                            ),
                          ),
                        ),
                        SizedBox(height: _responsive(context, 8)),
                        SizedBox(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.5,
                          child: Text(
                            category.name ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w700,
                              fontSize: _responsive(context, 14),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              });
            },
          )),
    );
  }

  Widget _buildCartSection(PosController controller, BuildContext context) {
    // bool _shouldShowSaveButtons(PosController controller) {
    //   return controller.cartItems.isNotEmpty || controller.customerDetails.isNotEmpty;
    // }
    return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_responsive(context, 5)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 5,),
                //
                // Padding(
                //   padding: EdgeInsets.only(left: 8.0,right: 8),
                //   child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text('OPEN ORDERS [10]',
                //         style: TextStyle(
                //         fontFamily: 'Mulish',
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //           decoration: TextDecoration.underline
                //       ),),
                //       Obx(() => Row(
                //         children: [
                //           Text('Invoice no : ',
                //             style: TextStyle(
                //                 fontFamily: 'Mulish',
                //                 fontSize: 12,
                //                 fontWeight: FontWeight.w400
                //             ),),
                //           Text('${controller.invoiceNumber.value}',
                //             style: TextStyle(
                //                 fontFamily: 'Mulish',
                //                 fontSize: 13,
                //                 fontWeight: FontWeight.w800
                //             ),),
                //         ],
                //       )),
                //     ],
                //   ),
                // ),
                Padding(
                  padding: EdgeInsets.all(_responsive(context, 8)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _responsive(context, 10),
                      vertical: _responsive(context, 6),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xffEDE4FF), width: 1),
                      borderRadius: BorderRadius.circular(
                          _responsive(context, 5)),
                      color: const Color(0xffFBF9FF),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phone Number / Name',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w500,
                            fontSize: _responsive(context, 14),
                            color: const Color(0xff797878),
                          ),
                        ),
                        Row(
                          children: [
                            Obx(() => GestureDetector(
                              onTap: () => controller.toggleDraftPanel(),
                              child: Container(
                                padding: EdgeInsets.all(_responsive(context, 8)),
                                decoration: BoxDecoration(
                                  color: controller.showDraftPanel.value
                                      ? const Color(0xff6C4AB6)
                                      : controller.drafts.isNotEmpty
                                          ? const Color(0xff6C4AB6).withOpacity(0.15)
                                          : const Color(0xffEDE4FF),
                                  borderRadius: BorderRadius.circular(_responsive(context, 6)),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.bookmark_outline_rounded,
                                      size: _responsive(context, 18),
                                      color: controller.showDraftPanel.value
                                          ? Colors.white
                                          : const Color(0xff6C4AB6),
                                    ),
                                    if (controller.drafts.isNotEmpty)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          width: _responsive(context, 14),
                                          height: _responsive(context, 14),
                                          decoration: const BoxDecoration(
                                            color: Color(0xff6C4AB6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${controller.drafts.length}',
                                              style: TextStyle(
                                                fontSize: _responsive(context, 8),
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Mulish',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                            SizedBox(width: _responsive(context, 6)),
                            GestureDetector(
                              onTap: () => controller.onAddCustomerPressed(),
                              child: Container(
                                padding: EdgeInsets.all(_responsive(context, 8)),
                                decoration: BoxDecoration(
                                  color: const Color(0xffB8ABD1),
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 6)),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/add-user.svg',
                                  height: _responsive(context, 18),
                                  width: _responsive(context, 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(_responsive(context, 4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildOrderTypeButton(controller, 'Lieferzeit',
                                  'assets/images/delivery-icon.svg', context),
                              SizedBox(width: _responsive(context, 8)),
                              _buildOrderTypeButton(controller, 'Abholzeit',
                                  'assets/images/pickup-icon.svg', context),
                            ],
                          ),
                          SizedBox(height: _responsive(context, 8)),
                          GestureDetector(
                            onTap: () => controller.showAddNoteDialog(context),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/note.png',
                                  height: 14,
                                  width: 14,
                                ),
                                SizedBox(width: _responsive(context, 5)),
                                Obx(
                                      () =>
                                      Text(
                                        controller.orderNote.value.isEmpty
                                            ? 'Note'
                                            : 'Note: ${controller.orderNote
                                            .value}',
                                      ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Obx(() {
                    if (controller.cartItems.isEmpty &&
                        !controller.showCustomerDetails.value) {
                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'No items in cart',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w500,
                                  fontSize: _responsive(context, 20),
                                  color: const Color(0xff797878),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsive(context, 12),
                              vertical: _responsive(context, 15),
                            ),
                            child: _buildSummarySection(controller, context),
                          ),
                        ],
                      );
                    }

                    if (controller.showCustomerDetails.value) {
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _responsive(context, 8),
                              vertical: _responsive(context, 12),
                            ),
                            child: _buildSummarySection(controller, context),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  if (controller.isCustomerFormVisible.value)
                                    _buildCustomerDetailsSection(
                                        controller, context),

                                  if (controller.customerDetails.isNotEmpty &&
                                      !controller.isCustomerFormVisible.value)
                                    _buildCustomerDetailsDisplay(
                                        controller, context),

                                  if (controller.customerDetails.isNotEmpty &&
                                      !controller.isCustomerFormVisible.value)
                                    _buildTodaySection(context),

                                  SizedBox(height: _responsive(context, 20)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildCartItems(controller, context),
                                SizedBox(height: _responsive(context, 20)),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsive(context, 8),
                            vertical: _responsive(context, 12),
                          ),
                          child: _buildSummarySection(controller, context),
                        ),
                      ],
                    );
                  }),
                ),

                // Obx(() {
                //   if (!_shouldShowSaveButtons(controller)) {
                //     return SizedBox.shrink();
                //   }
                //
                //   bool showBothButtons = controller.cartItems.isNotEmpty;
                //
                //   return Padding(
                //     padding: EdgeInsets.symmetric(
                //       horizontal: _responsive(context, 8),
                //       vertical: _responsive(context, 8),
                //     ),
                //     child: Row(
                //       children: [
                //         // Save Button
                //         Expanded(
                //           child: GestureDetector(
                //             onTap: () {
                //               controller.selectedSaveOption.value = 'save';  // ✅ Set selection
                //               print('Save clicked');
                //             },
                //             child: Container(
                //               padding: EdgeInsets.symmetric(
                //                 vertical: _responsive(context, 14),
                //               ),
                //               decoration: BoxDecoration(
                //                 borderRadius: BorderRadius.circular(_responsive(context, 8)),
                //                 color: controller.selectedSaveOption.value == 'save'  // ✅ Check selection
                //                     ? Color(0xff1A1F2E)  // Dark color when selected
                //                     : Color(0xffFBF9FF),
                //               ),
                //               child: Center(
                //                 child: Text(
                //                   'Save',
                //                   style: TextStyle(
                //                     fontWeight: FontWeight.w700,
                //                     fontSize: _responsive(context, 15),
                //                     fontFamily: 'Mulish',
                //                     color: controller.selectedSaveOption.value == 'save'  // ✅ Text color change
                //                         ? Colors.white
                //                         : Color(0xff0B1928),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //           ),
                //         ),
                //
                //         // Show Save & Print only if cart has items
                //         if (showBothButtons) ...[
                //           SizedBox(width: _responsive(context, 8)),
                //           Expanded(
                //             child: GestureDetector(
                //               onTap: () {
                //                 controller.selectedSaveOption.value = 'save_print';  // ✅ Set selection
                //                 print('Save & Print clicked');
                //               },
                //               child: Container(
                //                 padding: EdgeInsets.symmetric(
                //                   vertical: _responsive(context, 14),
                //                 ),
                //                 decoration: BoxDecoration(
                //                   borderRadius: BorderRadius.circular(_responsive(context, 8)),
                //                   color: controller.selectedSaveOption.value == 'save_print'  // ✅ Check selection
                //                       ? Color(0xff1A1F2E)  // Dark when selected
                //                       : Color(0xffFBF9FF),   // Keep dark (default state)
                //                 ),
                //                 child: Center(
                //                   child: Text(
                //                     'Save & Print',
                //                     style: TextStyle(
                //                       fontWeight: FontWeight.w700,
                //                       fontSize: _responsive(context, 15),
                //                       fontFamily: 'Mulish',
                //                       color: controller.selectedSaveOption.value == 'save_print'
                //                           ? Colors.white
                //                           : Color(0xff0B1928),
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //           ),
                //         ],
                //       ],
                //     ),
                //   );
                // }),

                _buildWeiterButton(controller, context),
              ],
            ),
          ),
          _buildTimeBottomSheet(controller, context),
          _buildCalendarBottomSheet(controller, context),
          _buildDraftPanel(controller, context),
        ]);
  }

  Widget _buildDraftPanel(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showDraftPanel.value) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_responsive(context, 5)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _responsive(context, 12),
                vertical: _responsive(context, 10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Drafts',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontWeight: FontWeight.w700,
                      fontSize: _responsive(context, 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.showDraftPanel.value = false,
                    child: Icon(Icons.close, size: _responsive(context, 20), color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xffEDE4FF)),
            Expanded(
              child: Obx(() {
                if (controller.drafts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: _responsive(context, 36), color: const Color(0xffB8ABD1)),
                        SizedBox(height: _responsive(context, 8)),
                        Text(
                          'No saved drafts',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontSize: _responsive(context, 13),
                            color: const Color(0xff797878),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.all(_responsive(context, 10)),
                  itemCount: controller.drafts.length,
                  separatorBuilder: (_, __) => SizedBox(height: _responsive(context, 6)),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: _responsive(context, 10),
                          vertical: _responsive(context, 8),
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffEDE4FF)),
                          borderRadius: BorderRadius.circular(_responsive(context, 6)),
                          color: const Color(0xffFBF9FF),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(_responsive(context, 6)),
                              decoration: BoxDecoration(
                                color: const Color(0xff6C4AB6).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.bookmark_rounded,
                                size: _responsive(context, 14),
                                color: const Color(0xff6C4AB6),
                              ),
                            ),
                            SizedBox(width: _responsive(context, 8)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Mulish',
                                      fontWeight: FontWeight.w600,
                                      fontSize: _responsive(context, 13),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: _responsive(context, 2)),
                                  Text(
                                    '${items.length} item${items.length == 1 ? '' : 's'}  •  $timeStr',
                                    style: TextStyle(
                                      fontFamily: 'Mulish',
                                      fontSize: _responsive(context, 11),
                                      color: const Color(0xff797878),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.deleteDraft(index),
                              child: Padding(
                                padding: EdgeInsets.all(_responsive(context, 4)),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: _responsive(context, 18),
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
    });
  }

  Widget _buildVariantDialog(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showVariantDialog.value ||
          controller.selectedProduct.value == null) {
        return const SizedBox.shrink();
      }

      var product = controller.selectedProduct.value!;
      var variants = product.variants ?? [];

      return Stack(
        children: [
          GestureDetector(
            onTap: () => controller.showVariantDialog.value = false,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Positioned(
            left: _responsive(context, 60),
            // Sidebar width
            right: MediaQuery
                .of(context)
                .size
                .width * 0.375,
            // Cart section width (3/8)
            top: 0,
            bottom: 0,
            child: Center(
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.4,
                  constraints: BoxConstraints(maxHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 0.8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        _responsive(context, 12)),),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(_responsive(context, 16)),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xffEDE4FF))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name ?? '',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 22),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(_responsive(context, 16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (variants.isNotEmpty) ...[
                                SizedBox(height: _responsive(context, 8)),
                                ...variants
                                    .map((variant) =>
                                    Obx(() {
                                      bool isSelected = controller
                                          .selectedVariant.value?.id ==
                                          variant.id;
                                      bool isExpanded = controller
                                          .expandedVariantId.value ==
                                          variant.id;

                                      return Column(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              controller
                                                  .selectVariant(variant);
                                            },
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  bottom: _responsive(
                                                      context, 5)),
                                              padding: EdgeInsets.all(
                                                  _responsive(context, 14)),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(
                                                    _responsive(
                                                        context, 8)),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? const Color(0xff0C831F)
                                                      : const Color(0xffEDE4FF),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: _responsive(
                                                        context, 20),
                                                    height: _responsive(
                                                        context, 20),
                                                    decoration:
                                                    BoxDecoration(
                                                      shape:
                                                      BoxShape.circle,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? const Color(
                                                            0xff0C831F)
                                                            : Colors.grey,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: isSelected
                                                        ? Center(
                                                      child:
                                                      Container(
                                                        width:
                                                        _responsive(
                                                            context,
                                                            10),
                                                        height:
                                                        _responsive(
                                                            context,
                                                            10),
                                                        decoration:
                                                        const BoxDecoration(
                                                          shape: BoxShape
                                                              .circle,
                                                          color: Color(
                                                              0xff0C831F),
                                                        ),
                                                      ),
                                                    )
                                                        : null,
                                                  ),
                                                  SizedBox(
                                                      width: _responsive(
                                                          context, 12)),
                                                  Expanded(
                                                    child: Text(
                                                      variant.name ?? '',
                                                      style: TextStyle(
                                                        fontFamily:
                                                        'Mulish',
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        fontSize:
                                                        _responsive(
                                                            context,
                                                            18),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '€${((variant.price ?? 0) /
                                                        100).toStringAsFixed(
                                                        2)}',
                                                    style: TextStyle(
                                                      fontFamily: 'Mulish',
                                                      fontWeight:
                                                      FontWeight.w700,
                                                      fontSize: _responsive(
                                                          context, 18),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Expandable toppings section
                                          if (isExpanded &&
                                              variant.enrichedToppingGroups !=
                                                  null &&
                                              variant.enrichedToppingGroups!
                                                  .isNotEmpty)
                                            Container(
                                              margin: EdgeInsets.only(
                                                left: _responsive(
                                                    context, 25),
                                                bottom:
                                                _responsive(context, 8),
                                              ),
                                              padding: EdgeInsets.all(
                                                  _responsive(context, 12)),
                                              decoration: BoxDecoration(
                                                color: const Color(0xffFBF9FF),
                                                borderRadius:
                                                BorderRadius.circular(
                                                    _responsive(
                                                        context, 8)),
                                                border: Border.all(
                                                    color:
                                                    const Color(0xffEDE4FF)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                                children: variant
                                                    .enrichedToppingGroups!
                                                    .map((group) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      if (group.toppings !=
                                                          null &&
                                                          group.toppings!
                                                              .isNotEmpty) ...[
                                                        ...group.toppings!
                                                            .map(
                                                                (topping) =>
                                                                Obx(() {
                                                                  bool
                                                                  isToppingSelected =
                                                                      controller
                                                                          .selectedToppingsMap[variant
                                                                          .id]
                                                                          ?.contains(
                                                                          topping
                                                                              .id) ??
                                                                          false;

                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      if (variant
                                                                          .id !=
                                                                          null &&
                                                                          topping
                                                                              .id !=
                                                                              null) {
                                                                        controller
                                                                            .toggleVariantTopping(
                                                                            variant
                                                                                .id!,
                                                                            topping
                                                                                .id!);
                                                                      }
                                                                    },
                                                                    child:
                                                                    Container(
                                                                      margin: EdgeInsets
                                                                          .only(
                                                                          bottom: _responsive(
                                                                              context,
                                                                              8)),
                                                                      child: Row(
                                                                        crossAxisAlignment: CrossAxisAlignment
                                                                            .start,
                                                                        children: [
                                                                          Container(
                                                                            width: _responsive(
                                                                                context,
                                                                                25),
                                                                            height: _responsive(
                                                                                context,
                                                                                25),
                                                                            decoration: BoxDecoration(
                                                                              border: Border
                                                                                  .all(
                                                                                color: isToppingSelected
                                                                                    ? const Color(
                                                                                    0xff0C831F)
                                                                                    : Colors
                                                                                    .grey,
                                                                                width: 2,
                                                                              ),
                                                                              borderRadius: BorderRadius
                                                                                  .circular(
                                                                                  4),
                                                                              color: isToppingSelected
                                                                                  ? const Color(
                                                                                  0xff0C831F)
                                                                                  : Colors
                                                                                  .transparent,
                                                                            ),
                                                                            child: isToppingSelected
                                                                                ? Icon(
                                                                                Icons
                                                                                    .check,
                                                                                size: _responsive(
                                                                                    context,
                                                                                    18),
                                                                                color: Colors
                                                                                    .white)
                                                                                : null,
                                                                          ),
                                                                          SizedBox(
                                                                              width: _responsive(
                                                                                  context,
                                                                                  8)),
                                                                          Expanded(
                                                                            child: Text(
                                                                              topping
                                                                                  .name ??
                                                                                  '',
                                                                              style: TextStyle(
                                                                                fontFamily: 'Mulish',
                                                                                fontWeight: FontWeight
                                                                                    .w700,
                                                                                fontSize: _responsive(
                                                                                    context,
                                                                                    15),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Text(
                                                                            '€${(topping
                                                                                .price ??
                                                                                0)
                                                                                .toStringAsFixed(
                                                                                2)}',
                                                                            style: TextStyle(
                                                                              fontFamily: 'Mulish',
                                                                              fontWeight: FontWeight
                                                                                  .w600,
                                                                              fontSize: _responsive(
                                                                                  context,
                                                                                  16),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                }))
                                                        ,
                                                        SizedBox(
                                                            height:
                                                            _responsive(
                                                                context,
                                                                8)),
                                                      ],
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      );
                                    }))
                                ,
                              ],
                              SizedBox(height: _responsive(context, 16)),
                            ],
                          ),
                        ),
                      ),

                      // Footer button
                      GestureDetector(
                        onTap: () => controller.addToCartWithVariant(),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(10),
                          padding: EdgeInsets.all(_responsive(context, 12)),
                          decoration: BoxDecoration(
                            color: const Color(0xff0C831F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Weiter €${_calculateDialogTotal(controller)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w700,
                              fontSize: _responsive(context, 22),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -12,
                  right: -12,
                  child: GestureDetector(
                    onTap: () => controller.showVariantDialog.value = false,
                    child: Container(
                      width: _responsive(context, 40),
                      height: _responsive(context, 40),
                      decoration: const BoxDecoration(
                        color: Color(0xffE31E24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          color: Colors.white, size: _responsive(context, 20)),
                    ),
                  ),
                )
              ]),
            ),
          ),
        ],
      );
    });
  }

  String _calculateDialogTotal(PosController controller) {
    if (controller.selectedProduct.value == null) return '0.00';

    double basePrice = double.tryParse(
        controller.selectedProduct.value!.price?.toString() ?? '0') ?? 0.0;
    double variantPrice = 0.0;
    double toppingPrice = 0.0;

    if (controller.selectedVariant.value != null) {
      variantPrice = (controller.selectedVariant.value!.price ?? 0).toDouble();

      // Calculate topping prices
      if (controller.selectedToppingsMap.containsKey(
          controller.selectedVariant.value!.id)) {
        var selectedToppingIds = controller.selectedToppingsMap[controller
            .selectedVariant.value!.id]!;

        controller.selectedVariant.value!.enrichedToppingGroups?.forEach((
            group) {
          group.toppings?.forEach((topping) {
            if (selectedToppingIds.contains(topping.id)) {
              toppingPrice += topping.price ?? 0.0;
            }
          });
        });
      }
    }

    return (basePrice + variantPrice + toppingPrice).toStringAsFixed(2);
  }

  Widget _buildOrderTypeButton(PosController controller, String type,
      String iconPath, BuildContext context)
  {
    return Obx(() {
      bool isSelected = controller.selectedOrderType.value == type;
      return GestureDetector(
        onTap: () => controller.setOrderType(type),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_responsive(context, 5)),
            color: isSelected ? const Color(0xff0C831F) : const Color(
                0xffFBF9FF),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                color: isSelected ? Colors.white : Colors.black,
                height: 13,
                width: 13,
              ),
              SizedBox(width: _responsive(context, 3)),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Mulish',
                  color: isSelected ? Colors.white : const Color(0xff0B1928),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCartItems(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.isCartExpanded.value) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _responsive(context, 4)),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.cartItems.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Color(0xffE6E1EE)),
            itemBuilder: (context, index) {
              final item = controller.cartItems[index];
              List<String> toppingsList = [];

              // Parse toppings from extras string
              if (item['extras'] != null && item['extras']
                  .toString()
                  .isNotEmpty) {
                toppingsList = item['extras'].toString().split('\n');
              }

              return Container(
                margin: EdgeInsets.all(_responsive(context, 2)),
                padding: EdgeInsets.all(_responsive(context, 8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name with quantity controls and price
                    // Product name with quantity controls and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cross button to remove item
                        GestureDetector(
                          onTap: () => controller.removeCartItem(index),
                          child: Icon(
                            Icons.close,
                            size: _responsive(context, 20),
                            color: const Color(0xffE31E24),
                          ),
                        ),
                        // Product name
                        SizedBox(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.15,
                          child: Text(
                            item['name'],
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.w700,
                              fontSize: _responsive(context, 12),
                            ),
                          ),
                        ),

                        // Note icon button
                        GestureDetector(
                          onTap: () =>
                              controller.showItemNoteDialog(context, index),
                          child: Image.asset(
                            'assets/images/note.png',
                            height: _responsive(context, 14),
                            width: _responsive(context, 14),
                            color: item['item_note'] != null &&
                                item['item_note']
                                    .toString()
                                    .isNotEmpty
                                ? const Color(0xff0C831F)
                                : const Color(0xff797878),
                          ),
                        ),

                        SizedBox(width: _responsive(context, 8)),

                        // Quantity controls
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => controller.decrementQuantity(index),
                              child: Container(
                                width: _responsive(context, 25),
                                height: _responsive(context, 25),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xffB8ABD1), width: 1),
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 4)),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: _responsive(context, 20),
                                  color: const Color(0xff0B1928),
                                ),
                              ),
                            ),
                            SizedBox(width: _responsive(context, 5)),
                            Text(
                              '${item['quantity']}',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 16),
                                color: const Color(0xff0B1928),
                              ),
                            ),
                            SizedBox(width: _responsive(context, 5)),
                            GestureDetector(
                              onTap: () => controller.incrementQuantity(index),
                              child: Container(
                                width: _responsive(context, 25),
                                height: _responsive(context, 25),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xffB8ABD1), width: 1),
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 4)),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: _responsive(context, 20),
                                  color: const Color(0xff0B1928),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(width: _responsive(context, 8)),

                        // Price
                        Text(
                          '€ ${(item['price'] * item['quantity'])
                              .toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: _responsive(context, 15),
                            color: const Color(0xff0B1928),
                          ),
                        ),
                      ],
                    ),

                    // Toppings list (without variant name)
                    if (toppingsList.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _responsive(context, 6),
                            left: _responsive(context, 12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: toppingsList.map((topping) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  bottom: _responsive(context, 2)),
                              child: Text(
                                '1× $topping',
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w500,
                                  fontSize: _responsive(context, 12),
                                  color: const Color(0xff797878),
                                ),
                              ),
                            );
                          }).toList(),

                        ),
                      ),
                    // Item note (if exists)
                    if (item['item_note'] != null && item['item_note']
                        .toString()
                        .isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _responsive(context, 4),
                            left: _responsive(context, 12)),
                        child: Row(
                          children: [
                            Text(
                              'Note: ',
                              style: TextStyle(
                                fontFamily: 'Mulish',
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item['item_note'],
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontWeight: FontWeight.w600,
                                  fontSize: _responsive(context, 11),
                                  color: const Color(0xff797878),

                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildSummarySection(PosController controller, BuildContext context) {
    double discountPercent = 0.0;
    if (controller.selectedOrderType.value == 'Lieferzeit') {
      discountPercent = controller.deliveryDiscount.value;
    } else if (controller.selectedOrderType.value == 'Abholzeit') {
      discountPercent = controller.pickupDiscount.value;
    }

    return Obx(() =>
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.all(_responsive(context, 12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_responsive(context, 12)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 7)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SubTotal',
                        style: TextStyle(
                          fontSize: _responsive(context, 16),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      Text(
                        '${controller.calculateSubtotal().toStringAsFixed(
                            2)} €',
                        style: TextStyle(
                          fontSize: _responsive(context, 16),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Discount (${discountPercent.toStringAsFixed(
                            0)}%)',
                        style: TextStyle(
                          fontSize: _responsive(context, 16),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: const Color(0xff00B10E),
                        ),
                      ),
                      Text(
                        '${controller.calculateDiscount().toStringAsFixed(
                            2)} €',
                        style: TextStyle(
                          fontSize: _responsive(context, 16),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xffB8ABD1), thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: _responsive(context, 20),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: const Color(0xff00B10E),
                        ),
                      ),
                      Text(
                        '${controller.calculateGrandTotal().toStringAsFixed(
                            2)} €',
                        style: TextStyle(
                          fontSize: _responsive(context, 20),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (controller.showCustomerDetails.value)
              Positioned(
                bottom: _responsive(context, -12),
                right: 0,
                child: InkWell(
                  onTap: () {
                    controller.toggleCustomerDetails();
                  },
                  child: Container(
                    padding: EdgeInsets.all(_responsive(context, 10)),
                    decoration: const BoxDecoration(
                      color: Color(0xff0B1928),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      controller.isCartExpanded.value
                          ? 'assets/images/drop.svg'
                          : 'assets/images/dropdown.svg',
                      color: Colors.white,
                      width: _responsive(context, 8),
                      height: _responsive(context, 8),
                    ),
                  ),
                ),
              ),
          ],
        ));
  }

  Widget _buildCustomerDetailsSection(PosController controller,
      BuildContext context)
  {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _responsive(context, 8)),
      padding: EdgeInsets.all(_responsive(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
        border: Border.all(color: const Color(0xffE6E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/user.svg',
                height: _responsive(context, 14),
                width: _responsive(context, 14),
              ),
              SizedBox(width: _responsive(context, 5)),
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: _responsive(context, 15),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
          SizedBox(height: _responsive(context, 12)),

          // Name Field
          _buildTextField(
            'Ihre Name *',
            controller.nameController,
            context,
            focusNode: controller.nameFocusNode,
            nextFocusNode: controller.phoneFocusNode,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),

          // Phone Field
          _buildTextField(
            'Ihre Telefonnummer *',
            controller.phoneController,
            context,
            focusNode: controller.phoneFocusNode,
            nextFocusNode: controller.addressFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _responsive(context, 8)),
          // Address Field
          _buildTextField(
            'Adresse *',
            controller.addressController,
            context,
            focusNode: controller.addressFocusNode,
            nextFocusNode: null, // ✅ Remove next focus - handle manually
            keyboardType: TextInputType.streetAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              // ✅ When next is pressed on address field
              if (controller.selectedOrderType.value == 'Lieferzeit') {
                FocusScope.of(context).unfocus(); // Close keyboard
                controller.showPostcodeSelector(context); // Open postcode popup
              } else {
                FocusScope.of(context).requestFocus(controller.regionFocusNode);
              }
            },
          ),
          SizedBox(height: _responsive(context, 8)),
          GestureDetector(
            onTap: controller.selectedOrderType.value == 'Lieferzeit'
                ? () => controller.showPostcodeSelector(context)
                : null,
            child: AbsorbPointer(
              absorbing: controller.selectedOrderType.value == 'Lieferzeit',
              child: _buildTextField(
                controller.selectedOrderType.value == 'Lieferzeit'
                    ? 'Wählen Sie Postleitzahl *'
                    : 'Wählen Sie Ihre Region *',
                controller.regionController,
                context,
                focusNode: controller.selectedOrderType.value == 'Lieferzeit'
                    ? null  // ✅ No focus node for postcode (read-only)
                    : controller.regionFocusNode,
                nextFocusNode: controller.emailFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                readOnly: controller.selectedOrderType.value == 'Lieferzeit', // ✅ Make read-only
                suffixIcon: controller.selectedOrderType.value == 'Lieferzeit'
                    ? const Icon(Icons.arrow_drop_down, color: Color(0xff0B1928))
                    : null,
              ),
            ),
          ),
          SizedBox(height: _responsive(context, 8)),
          // Email Field
          _buildTextField(
            'Ihre E-Mail',
            controller.emailController,
            context,
            focusNode: controller.emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),


        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller,
      BuildContext context,
      {FocusNode? focusNode,
        FocusNode? nextFocusNode,
        TextInputType? keyboardType,
        TextInputAction? textInputAction,
        Widget? suffixIcon,
        bool readOnly = false, // ✅ Add readOnly parameter
        Function(String)? onFieldSubmitted})
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _responsive(context, 12),
            fontWeight: FontWeight.w600,
            fontFamily: 'Mulish',
          ),
        ),
        SizedBox(height: _responsive(context, 4)),
        TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly, // ✅ Add readOnly property
          keyboardType: keyboardType ?? TextInputType.text,
          textInputAction: textInputAction ?? TextInputAction.next,
          onSubmitted: (value) {
            if (onFieldSubmitted != null) {
              onFieldSubmitted(value); // ✅ Use custom callback if provided
            } else if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          style: TextStyle(
            fontSize: _responsive(context, 18),
            fontFamily: 'Mulish',
          ),
          decoration: InputDecoration(
            hintText: label.split('*')[0].trim(),
            hintStyle: TextStyle(
              fontSize: _responsive(context, 15),
              fontFamily: 'Mulish',
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: _responsive(context, 8),
              vertical: _responsive(context, 8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_responsive(context, 4)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_responsive(context, 4)),
              borderSide: const BorderSide(color: Color(0xffE31E24)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsDisplay(PosController controller,
      BuildContext context)
  {
    return Obx(() =>
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: _responsive(context, 8),
            vertical: _responsive(context, 8),
          ),
          padding: EdgeInsets.all(_responsive(context, 12)),
          decoration: BoxDecoration(
            color: const Color(0xffFBF9FF),
            borderRadius: BorderRadius.circular(_responsive(context, 8)),
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
                        height: _responsive(context, 14),
                        width: _responsive(context, 14),
                      ),
                      SizedBox(width: _responsive(context, 5)),
                      Text(
                        'Customer Details',
                        style: TextStyle(
                          fontSize: _responsive(context, 14),
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: controller.editCustomerDetails,
                    child: Container(
                      padding: EdgeInsets.all(_responsive(context, 4)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            _responsive(context, 4)),
                      ),
                      child: Image.asset(
                        'assets/images/note.png',
                        height: _responsive(context, 20),
                        width: _responsive(context, 20),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _responsive(context, 8)),
              const Divider(color: Color(0xffE6E1EE), thickness: 1),
              SizedBox(height: _responsive(context, 8)),
              _buildDetailRow(
                  'Ihre Name', controller.customerDetails['name'] ?? '',
                  context),
              SizedBox(height: _responsive(context, 4)),
              _buildDetailRow('Ihre Telefonnummer',
                  controller.customerDetails['phone'] ?? '', context),
              SizedBox(height: _responsive(context, 4)),
              _buildDetailRow(
                  'Address', controller.customerDetails['address'] ?? '',
                  context),
              SizedBox(height: _responsive(context, 4)),
              _buildDetailRow(
                  'Region', controller.customerDetails['region'] ?? '',
                  context),
              SizedBox(height: _responsive(context, 4)),
              if (controller.customerDetails['email']?.isNotEmpty ?? false)
                _buildDetailRow(
                    'Ihre E-Mail', controller.customerDetails['email'] ?? '',
                    context),


            ],
          ),
        ));
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: _responsive(context, 11),
            fontWeight: FontWeight.w700,
            fontFamily: 'Mulish',
            color: const Color(0xff797878),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: _responsive(context, 11),
              fontWeight: FontWeight.w600,
              fontFamily: 'Mulish',
              color: const Color(0xff0B1928),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _responsive(context, 8),
        vertical: _responsive(context, 8),
      ),
      padding: EdgeInsets.all(_responsive(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsive(context, 8)),
        border: Border.all(color: const Color(0xffE6E1EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() =>
              GestureDetector(
                onTap: () => controller.selectHeute(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 12)),
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(_responsive(context, 8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _responsive(context, 24),
                        height: _responsive(context, 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xff0B1928),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(_responsive(
                              context, 4)),
                        ),
                        child: controller.isHeuteSelected.value ?
                        Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: controller.isHeuteSelected.value
                                ? const Color(0xff0C831F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                _responsive(context, 4)),
                          ),
                        )
                            : null,
                      ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        'Heute',
                        style: TextStyle(
                          fontSize: _responsive(context, 14),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: const Color(0xff0B1928),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          SizedBox(height: _responsive(context, 12)),

          Obx(() =>
          controller.isHeuteSelected.value
              ? GestureDetector(
            onTap: () => controller.openTimeBottomSheet(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _responsive(context, 12),
                vertical: _responsive(context, 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xffFBF9FF),
                borderRadius:
                BorderRadius.circular(_responsive(context, 6)),
                border: Border.all(color: const Color(0xffE6E1EE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.selectedTimeSlot.value,
                    style: TextStyle(
                      fontSize: _responsive(context, 12),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Mulish',
                      color: const Color(0xff0B1928),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: _responsive(context, 16),
                    color: const Color(0xff0B1928),
                  ),
                ],
              ),
            ),
          )
              : const SizedBox.shrink()),

          SizedBox(height: _responsive(context, 12)),

          Obx(() =>
              GestureDetector(
                onTap: () => controller.selectVorbestellen(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 12)),
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(_responsive(context, 8)),

                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _responsive(context, 24),
                        height: _responsive(context, 24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xff0B1928),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(_responsive(
                              context, 4)),
                        ),
                        child: controller.isVorbestellenSelected.value
                            ? Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: controller.isVorbestellenSelected.value
                                ? const Color(0xff0C831F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                _responsive(context, 4)),
                          ),
                        )
                            : null,
                      ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        'Vorbestellen',
                        style: TextStyle(
                          fontSize: _responsive(context, 14),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                          color: const Color(0xff0B1928),
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          SizedBox(height: _responsive(context, 12)),

          Obx(() =>
          controller.isVorbestellenSelected.value
              ? Column(
            children: [
              GestureDetector(
                onTap: () => controller.openCalendar(),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _responsive(context, 12),
                    vertical: _responsive(context, 10),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFBF9FF),
                    borderRadius:
                    BorderRadius.circular(_responsive(context, 6)),
                    border: Border.all(color: const Color(0xffE6E1EE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.selectedDate.value != null
                            ? '${controller.selectedDate.value!.day}.${controller.selectedDate.value!.month}.${controller.selectedDate.value!.year}'
                            : 'Select Date',
                        style: TextStyle(
                          fontSize: _responsive(context, 12),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Mulish',
                          color: const Color(0xff797878),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(_responsive(context, 6)),
                        decoration: BoxDecoration(
                          color: const Color(0xffE31E24),
                          borderRadius: BorderRadius.circular(
                              _responsive(context, 4)),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: _responsive(context, 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.showTimeSelector.value &&
                  controller.selectedDate.value != null)
                Padding(
                  padding: EdgeInsets.only(top: _responsive(context, 12)),
                  child: GestureDetector(
                    onTap: () => controller.openTimeSelector(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _responsive(context, 12),
                        vertical: _responsive(context, 10),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFBF9FF),
                        borderRadius: BorderRadius.circular(
                            _responsive(context, 6)),
                        border: Border.all(color: const Color(0xffE6E1EE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.selectedTimeSlot.value != 'sofort' && controller.selectedDate.value != null
                                ? controller.selectedTimeSlot.value
                                : 'Select Time',
                            style: TextStyle(
                              fontSize: _responsive(context, 12),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Mulish',
                              color: const Color(0xff797878),
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            size: _responsive(context, 16),
                            color: const Color(0xff0B1928),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )
              : const SizedBox.shrink()),

          SizedBox(height: _responsive(context, 16)),
          const Divider(color: Color(0xffE6E1EE), thickness: 1),
          SizedBox(height: _responsive(context, 12)),

          Text(
            'Zahlungsmethode auswählen',
            style: TextStyle(
              fontSize: _responsive(context, 13),
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish',
              color: const Color(0xff0B1928),
            ),
          ),
          SizedBox(height: _responsive(context, 12)),
          Row(children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _responsive(context, 10),
                  horizontal: _responsive(context, 4),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_responsive(context, 6)),
                  border: Border.all(color: const Color(0xffE31E24), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: const Color(0xffE31E24),
                      size: _responsive(context, 16),
                    ),
                    SizedBox(width: _responsive(context, 3)),
                    Text(
                      'Online-Zahlung',
                      style: TextStyle(
                        fontSize: _responsive(context, 11),
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mulish',
                        color: const Color(0xffE31E24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: _responsive(context, 10)),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: _responsive(context, 10),
                  horizontal: _responsive(context, 12),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff232D3F),
                  borderRadius: BorderRadius.circular(_responsive(context, 6)),
                ),
                child:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                    size: _responsive(context, 16),
                  ),
                  SizedBox(width: _responsive(context, 6)),
                  Text(
                    'Bar',
                    style: TextStyle(
                      fontSize: _responsive(context, 11),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildWeiterButton(PosController controller, BuildContext context) {
    final radius = _responsive(context, 5);
    return Obx(() {
      final bool hasItems = controller.cartItems.isNotEmpty;
      return Container(
        padding: EdgeInsets.only(left: 15,right: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Save as Draft button
            Expanded(
              child: GestureDetector(
                onTap: hasItems ? () => controller.saveAsDraft() : null,
                child: Container(
                  width: 100,
                  padding: EdgeInsets.all(8.5),
                  decoration: BoxDecoration(
                    color: hasItems
                        ? const Color(0xff6C4AB6)
                        : const Color(0xffB8ABD1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(radius),
                    ),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_outline_rounded,
                        size: _responsive(context, 14),
                        color: Colors.white,
                      ),
                      SizedBox(width: _responsive(context, 4)),
                      Text(
                        'Draft',
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontWeight: FontWeight.w700,
                          fontSize: _responsive(context, 13),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Weiter / Place Order button
            Expanded(
              child: GestureDetector(
                onTap: controller.onWeiterPressed,
                child: Container(
                  // padding: EdgeInsets.symmetric(
                  //   vertical: _responsive(context, 12),
                  // ),
                  width: 100,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff0C831F),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      controller.customerDetails.isEmpty ? 'Weiter' : 'Place Order',
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        fontWeight: FontWeight.w700,
                        fontSize: _responsive(context, 14),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTimeBottomSheet(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showTimeBottomSheet.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.375,
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Stack(clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(_responsive(context, 16)),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xffE6E1EE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                              width: _responsive(context, 35),
                              height: _responsive(context, 35),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xff0B1928),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                    _responsive(context, 6)),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xff0C831F),
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 4)),
                                ),
                              )
                          ),
                      SizedBox(width: _responsive(context, 12)),
                      Text(
                        controller.isVorbestellenSelected.value
                            ? (controller.selectedDate.value != null
                                ? '${controller.selectedDate.value!.day}.${controller.selectedDate.value!.month}.${controller.selectedDate.value!.year}'
                                : 'Select Date')
                            : 'Heute',
                        style: TextStyle(
                          fontSize: _responsive(context, 18),
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                    ),
                    Positioned(
                      top: -18, right: 15,
                      child: InkWell(
                        onTap: () => controller.closeTimeBottomSheet(),
                        child: Container(

                          width: _responsive(context, 55),
                          height: _responsive(context, 55),
                          decoration: const BoxDecoration(
                            color: Color(0xffE31E24),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: _responsive(context, 40),
                          ),
                        ),
                      ),)
                  ]),
              Obx(() {
              
                if (controller.isHeuteSelected.value && !controller.isStoreOpen.value) {
                  return Padding(
                    padding: EdgeInsets.all(_responsive(context, 20)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_mall_directory_outlined,
                          size: _responsive(context, 60),
                          color: Colors.grey,
                        ),
                        SizedBox(height: _responsive(context, 16)),
                        Text(
                          'Store is Currently Closed',
                          style: TextStyle(
                            fontSize: _responsive(context, 18),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mulish',
                          ),
                        ),
                        SizedBox(height: _responsive(context, 8)),
                        Text(
                          'Please use "Vorbestellen" to schedule your order',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _responsive(context, 14),
                            color: Colors.grey,
                          ),
                        ),
                        if (controller.storeOpeningTime.value != null) ...[
                          SizedBox(height: _responsive(context, 12)),
                          Text(
                            'Opens at: ${controller.storeOpeningTime.value!.hour.toString().padLeft(2, '0')}:${controller.storeOpeningTime.value!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: _responsive(context, 16),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff0C831F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                if (controller.sofortTimeSlots.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(_responsive(context, 12)),
                    child: Text(
                      'No time slots available',
                      style: TextStyle(
                        fontSize: _responsive(context, 16),
                        color: Colors.grey,
                      ),
                    ),
                  );
                }



                return Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: _responsive(context, 16)),
                    child: Column(
                      children: [

                        if (controller.isHeuteSelected.value)
                          GestureDetector(
                            onTap: () => controller.selectTimeSlot('sofort'),
                            child: Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(
                                  bottom: _responsive(context, 12)),
                              padding: EdgeInsets.symmetric(
                                  vertical: _responsive(context, 8)),
                              decoration: BoxDecoration(
                                color: controller.selectedTimeSlot.value ==
                                    'sofort'
                                    ? const Color(0xff0C831F)
                                    : const Color(0xffFBF9FF),
                                borderRadius: BorderRadius.circular(
                                    _responsive(context, 5)),
                                border: Border.all(
                                  color: const Color(0xff0C831F),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'sofort',
                                  style: TextStyle(
                                    fontSize: _responsive(context, 18),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                    color: controller.selectedTimeSlot.value ==
                                        'sofort'
                                        ? Colors.white
                                        : const Color(0xff0B1928),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: _responsive(context, 5),
                            mainAxisSpacing: _responsive(context, 5),
                            childAspectRatio: 2.3,
                          ),
                          itemCount: controller.sofortTimeSlots.length,
                          itemBuilder: (context, index) {
                            String timeSlot = controller
                                .sofortTimeSlots[index]['time24']!;
                            bool isSelected = controller.selectedTimeSlot
                                .value == timeSlot;

                            return GestureDetector(
                              onTap: () => controller.selectTimeSlot(timeSlot),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xff0C831F)
                                      : const Color(0xffE9F6EF),
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 4)),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xff0C831F)
                                        : const Color(0xff0C831F),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    timeSlot,
                                    style: TextStyle(
                                      fontSize: _responsive(context, 16),
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Mulish',
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xff0B1928),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCalendarBottomSheet(PosController controller,
      BuildContext context)
  {
    return Obx(() {
      if (!controller.showCalendar.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.375,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Stack(clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(_responsive(context, 16)),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(
                            0xffE6E1EE))),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${DateFormat('MMMM').format(
                                controller.getCurrentGermanyDate())},',
                            style: TextStyle(
                              fontSize: _responsive(context, 20),
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${controller
                                .getCurrentGermanyDate()
                                .year}',
                            style: TextStyle(
                              fontSize: _responsive(context, 18),
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Mulish',
                              color: const Color(0xff0C831F),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(
                              0xff0C831F)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -18, right: 15,
                      child: InkWell(
                        onTap: () => controller.closeCalendar(),
                        child: Container(
                          width: _responsive(context, 55),
                          height: _responsive(context, 55),
                          decoration: const BoxDecoration(
                            color: Color(0xffE31E24),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: _responsive(context, 40),
                          ),
                        ),
                      ),)
                  ]),

              // Calendar Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(_responsive(context, 16)),
                  child: Column(
                    children: [
                      // Week days header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((
                            day) =>
                            Container(
                              padding: const EdgeInsets.all(2),
                              width: _responsive(context, 50),
                              decoration: const BoxDecoration(
                                color: Color(0xff0B1928),
                              ),
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: _responsive(context, 14),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Mulish',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                      SizedBox(height: _responsive(context, 10)),

                      Expanded(
                        child: Builder(
                          builder: (context) {
                            DateTime now = controller.getCurrentGermanyDate();
                            int currentYear = now.year;
                            int currentMonth = now.month;

                            // Get first day of month (1-7, Monday=1, Sunday=7)
                            DateTime firstDayOfMonth = DateTime(
                                currentYear, currentMonth, 1);
                            int firstWeekday = firstDayOfMonth
                                .weekday; // 1=Mon, 7=Sun

                            // Convert to calendar format (Sunday=0, Saturday=6)
                            int startingOffset = firstWeekday == 7
                                ? 0
                                : firstWeekday;

                            // Days in current month
                            int daysInMonth = DateTime(
                                currentYear, currentMonth + 1, 0).day;

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: _responsive(context, 4),
                                crossAxisSpacing: _responsive(context, 4),
                              ),
                              itemCount: startingOffset + daysInMonth,
                              itemBuilder: (context, index) {
                                // Empty cells before first day
                                if (index < startingOffset) {
                                  return Container();
                                }

                                int day = index - startingOffset + 1;
                                DateTime dateToCheck = DateTime(
                                    currentYear, currentMonth, day);

                                bool isPastDate = controller.isDateInPast(
                                    dateToCheck);
                                bool isSelected = controller.selectedDate.value
                                    ?.day == day &&
                                    controller.selectedDate.value?.month ==
                                        currentMonth;

                                return GestureDetector(
                                  onTap: () {
                                    if (!isPastDate) {
                                      controller.selectDate(dateToCheck);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isPastDate
                                          ? Colors.grey.shade300
                                          : (isSelected ? const Color(
                                          0xff0C831F) : Colors.transparent),
                                      border: Border.all(
                                          color: const Color(0xffEEF5FF),
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$day',
                                        style: TextStyle(
                                          fontSize: _responsive(context, 14),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Mulish',
                                          color: isPastDate
                                              ? Colors.grey.shade500
                                              : (isSelected
                                              ? Colors.white
                                              : const Color(0xff0B1928)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
        ),
      );
    });
  }

  Widget _buildPostcodeDialog(PosController controller, BuildContext context) {
    return Obx(() {
      if (!controller.showPostcodeDialog.value) {
        return const SizedBox.shrink();
      }

      return Stack(
        children: [
          GestureDetector(
            onTap: () => controller.showPostcodeDialog.value = false,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_responsive(context, 12)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(_responsive(context, 16)),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(
                          0xffEDE4FF))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Postcode',
                          style: TextStyle(
                            fontFamily: 'Mulish',
                            fontWeight: FontWeight.w700,
                            fontSize: _responsive(context, 18),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                          controller.showPostcodeDialog.value = false,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() =>
                        ListView.builder(
                          padding: EdgeInsets.all(_responsive(context, 16)),
                          itemCount: controller.postcode.length,
                          itemBuilder: (context, index) {
                            var postcodeItem = controller.postcode[index];
                            bool isSelected = controller.selectedPostcode.value
                                ?.id == postcodeItem.id;

                            return GestureDetector(
                              onTap: () =>
                                  controller.selectPostcode(postcodeItem),
                              child: Container(
                                margin: EdgeInsets.only(
                                    bottom: _responsive(context, 8)),
                                padding: EdgeInsets.all(
                                    _responsive(context, 12)),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xff0C831F)
                                      .withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      _responsive(context, 8)),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xff0C831F)
                                        : const Color(0xffEDE4FF),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          postcodeItem.postcode ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Mulish',
                                            fontWeight: FontWeight.w700,
                                            fontSize: _responsive(context, 16),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Delivery: ${postcodeItem
                                              .deliveryTime ?? 0} min',
                                          style: TextStyle(
                                            fontFamily: 'Mulish',
                                            fontWeight: FontWeight.w500,
                                            fontSize: _responsive(context, 12),
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle,
                                          color: Color(0xff0C831F)),
                                  ],
                                ),
                              ),
                            );
                          },
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildOrdersSection(PosController controller, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 5),
        // Header with back button
        _buildOrdersHeader(controller, context),
        SizedBox(height: _responsive(context, 10)),
        // Stats Row
        _buildOrderStatsRow(controller, context),
        SizedBox(height: _responsive(context, 15)),
        // Orders Grid
        Expanded(
          child: _buildOrdersGrid(controller, context),
        ),
      ],
    );
  }

  Widget _buildOrdersHeader(PosController controller, BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(_responsive(context, 15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Back button to return to products
              GestureDetector(
                onTap: () {
                  controller.hideOrderOverlay();
                },
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 8)),
                  decoration: BoxDecoration(
                    color: const Color(0xffFBF9FF),
                    borderRadius: BorderRadius.circular(_responsive(context, 5)),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: _responsive(context, 20),
                  ),
                ),
              ),
              SizedBox(width: _responsive(context, 12)),
              Image.asset(
                'assets/images/mirch.png',
                height: 25,
                width: 25,
              ),
              SizedBox(width: _responsive(context, 12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: _responsive(context, 18),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Mulish',
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM, y').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: _responsive(context, 14),
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Obx(() => Text(
                'Total: ${controller.orderStats['totalOrders']}',
                style: TextStyle(
                  fontSize: _responsive(context, 14),
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Mulish',
                ),
              )),
              SizedBox(width: _responsive(context, 8)),
              GestureDetector(
                onTap: () => controller.loadOrders(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 10)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_responsive(context, 5)),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: const Color(0xffE31E24),
                    size: _responsive(context, 20),
                  ),
                ),
              ),
              SizedBox(width: _responsive(context, 8)),
              GestureDetector(
                onTap: () => controller.syncLocalOrders(),
                child: Container(
                  padding: EdgeInsets.all(_responsive(context, 10)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_responsive(context, 5)),
                  ),
                  child: Icon(
                    Icons.sync,
                    color: const Color(0xffE31E24),
                    size: _responsive(context, 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatsRow(PosController controller, BuildContext context) {
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: _responsive(context, 4)),
      child: Row(
        children: [
          _buildOrderStatCard(
            context,
            'Accepted ${controller.orderStats['accepted']}',
            Colors.green.withOpacity(0.1),
          ),
          SizedBox(width: _responsive(context, 8)),
          _buildOrderStatCard(
            context,
            'Declined ${controller.orderStats['declined']}',
            Colors.red.withOpacity(0.1),
          ),
          SizedBox(width: _responsive(context, 8)),
          _buildOrderStatCard(
            context,
            'Pickup ${controller.orderStats['pickup']}',
            Colors.blue.withOpacity(0.1),
          ),
          SizedBox(width: _responsive(context, 8)),
          _buildOrderStatCard(
            context,
            'Delivery ${controller.orderStats['delivery']}',
            Colors.purple.withOpacity(0.1),
          ),
        ],
      ),
    ));
  }

  Widget _buildOrderStatCard(BuildContext context, String text, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _responsive(context, 8),
        vertical: _responsive(context, 6),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_responsive(context, 6)),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Mulish',
          fontWeight: FontWeight.w700,
          fontSize: _responsive(context, 11),
          color: Colors.black87,
        ),
      ),
    );
  }

  // ✅ Orders grid
  Widget _buildOrdersGrid(PosController controller, BuildContext context) {
    return Obx(() {
      if (controller.isLoadingOrders.value) {
        return Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: _responsive(context, 150),
            height: _responsive(context, 150),
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
                width: _responsive(context, 150),
                height: _responsive(context, 150),
              ),
              Text(
                'No Orders',
                style: TextStyle(
                  fontSize: _responsive(context, 16),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  fontFamily: 'Mulish',
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.all(_responsive(context, 8)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: _responsive(context, 8),
          mainAxisSpacing: _responsive(context, 8),
          childAspectRatio: 2.6,
        ),
        itemCount: allOrders.length,
        itemBuilder: (context, index) {
          final order = allOrders[index];
          final isLocalOrder = controller.localOrdersList.contains(order);
          return _buildOrderCard(context, controller, order, isLocalOrder);
        },
      );
    });
  }

  // ✅ Order card
  Widget _buildOrderCard(
      BuildContext context,
      PosController controller,
      Order order,
      bool isLocalOrder,
      )
  {
    DateTime dateTime;
    try {
      if (order.isLocalOrder == true) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(order.createdAt.toString()),
        );
      } else {
        dateTime = DateTime.parse(order.createdAt.toString());
      }
    } catch (e) {
      dateTime = DateTime.now();
    }

    String time = DateFormat('hh:mm a').format(dateTime);
    String guestAddress = order.guestShippingJson?.zip?.toString() ?? '';
    String guestName = order.guestShippingJson?.customerName?.toString() ?? '';
    String guestPhone = order.guestShippingJson?.phone?.toString() ?? '';

    Color getContainerColor() {
      if (order.source == 'pos') return const Color(0xffF7F3FF);
      switch (order.approvalStatus) {
        case 2: return const Color(0xffEBFFF4);
        case 3: return const Color(0xffFFEFEF);
        case 1: return Colors.white;
        default: return Colors.white;
      }
    }

    Color getBorderColor() {
      if (order.source == 'pos') return const Color(0xffB8ABD1);
      switch (order.approvalStatus) {
        case 2: return const Color(0xffC3F2D9);
        case 3: return const Color(0xffFFD0D0);
        default: return Colors.grey.withOpacity(0.2);
      }
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => OrderDetailEnglish(order));
      },
      child: Container(
        decoration: BoxDecoration(
          color: getContainerColor(),
          borderRadius: BorderRadius.circular(_responsive(context, 7)),
          border: Border.all(color: getBorderColor(), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(_responsive(context, 8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: _responsive(context, 15),
                        backgroundColor: Colors.green,
                        child: SvgPicture.asset(
                          order.orderType == 1
                              ? 'assets/images/ic_delivery.svg'
                              : order.orderType == 2
                              ? 'assets/images/ic_pickup.svg'
                              : 'assets/images/table.svg',
                          height: _responsive(context, 12),
                          width: _responsive(context, 12),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: _responsive(context, 6)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.1,
                            child: Text(order.orderType == 2 ? 'Pickup' : (order.shipping_address?.zip?.toString() ?? guestAddress),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: _responsive(context, 12),
                                fontFamily: 'Mulish',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty)
                            Text(
                              'Time: ${controller.extractTime(order.deliveryTime!)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: _responsive(context, 11),
                                fontFamily: 'Mulish',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: _responsive(context, 17)),
                      SizedBox(width: _responsive(context, 3)),
                      Text(
                        time,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: _responsive(context, 12),
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: _responsive(context, 12)),

              // Customer Info
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.shipping_address?.customer_name ?? guestName} / ${order.shipping_address?.phone ?? guestPhone}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: _responsive(context, 13),
                      fontFamily: 'Mulish',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'Order #${order.orderNumber ?? order.id ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: _responsive(context, 12),
                      fontFamily: 'Mulish',
                    ),
                  ),
                ],
              ),

              SizedBox(height: _responsive(context, 20)),

              // Footer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '€ ${controller.formatAmount(order.payment?.amount ?? 0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: _responsive(context, 18),
                      fontFamily: 'Mulish',
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isLocalOrder
                            ? "Syncing"
                            : controller.getApprovalStatusText(order.approvalStatus),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: _responsive(context, 14),
                          fontFamily: 'Mulish',
                        ),
                      ),
                      SizedBox(width: _responsive(context, 4)),
                      isLocalOrder
                          ? RotationTransition(
                        turns: _syncRotationAnimation,
                        child: Icon(
                          Icons.sync,
                          size: _responsive(context, 16),
                          color: Colors.orange,
                        ),
                      )
                          : CircleAvatar(
                        radius: _responsive(context, 12),
                        backgroundColor: controller.getStatusColor(order.approvalStatus ?? 0),
                        child: Icon(
                          controller.getStatusIcon(order.approvalStatus ?? 0),
                          color: Colors.white,
                          size: _responsive(context, 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

