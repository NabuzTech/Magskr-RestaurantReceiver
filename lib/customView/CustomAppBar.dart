import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_receiver/ui/Store%20Owners/store_owner_stores.dart';
import 'package:food_receiver/ui/SuperAdmin/Admin%20Home/super_admin.dart';

import 'package:get/get.dart';

import '../api/repository/api_repository.dart';
import '../constants/app_theme.dart';
import '../constants/constant.dart';
import '../utils/my_application.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int? roleId;

  const CustomAppBar({super.key, this.roleId});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _CustomAppBarState extends State<CustomAppBar> {
  TextEditingController searchControllerTodo = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  String get currentSearchQuery => searchControllerTodo.text;
  // Shared by every CustomAppBar so the store API is hit once per app run.
  static String? _storeName;
  static String? _logoUrl;

  @override
  void initState() {
    super.initState();
    searchControllerTodo.addListener(_onSearchTextChanged);
    _loadStore();
  }

  Future<void> _loadStore() async {
    if (_logoUrl != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_storeName == null && mounted) {
      setState(() => _storeName =
          prefs.getString(valueShared_STORE_NAME) ?? prefs.getString('store_name'));
    }
    final bearer = prefs.getString(valueShared_BEARER_KEY);
    final storeId = prefs.getString(valueShared_STORE_KEY);
    if (bearer == null || storeId == null) return;
    try {
      final store = await ApiRepo().getStoreData(bearer, storeId);
      final url = store.imageUrl ?? '';
      final q = url.indexOf('?');
      if (!mounted) return;
      setState(() {
        _logoUrl = q == -1 ? url : url.substring(0, q);
        if (store.name != null && store.name!.isNotEmpty) _storeName = store.name;
      });
    } catch (e) {
      print('CustomAppBar store load failed: $e');
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'good_morning'.tr;
    if (h >= 12 && h < 17) return 'good_afternoon'.tr;
    if (h >= 17 && h < 21) return 'good_evening'.tr;
    return 'good_night'.tr;
  }

  @override
  void dispose() {
    searchFocusNode.unfocus();
    searchControllerTodo.removeListener(_onSearchTextChanged);
    searchControllerTodo.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final searchText = searchControllerTodo.text;
    print("🔍 Search text changed: '$searchText'");


    String currentRoute = Get.currentRoute;
    print("📍 Current route: $currentRoute");

    if (currentRoute == '/Products') {
      // Call products filter
      if (app.appController.productsFilterCallback != null) {
        app.appController.productsFilterCallback!(searchText);
        print("✅ Called products filter");
      }
    } else if (currentRoute == '/Category') {
      // Call category filter
      if (app.appController.categoryFilterCallback != null) {
        app.appController.categoryFilterCallback!(searchText);
        print("✅ Called category filter");
      }
    } else if (currentRoute == '/StoreCustomer') {
      if (app.appController.customerFilterCallback != null) {
        app.appController.customerFilterCallback!(searchText);
      }
    }else if (app.appController.selectedTabIndex == 0) {
      // Fallback to order filter for tab 0
      app.appController.filterSearchResultsTodo(searchText);
    } else if (app.appController.selectedTabIndex == 1) {
      // Fallback to reservation filter for tab 1
      app.appController.filterSearchResultsReservation(searchText);
    }
  }

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
    // Small delay to ensure widget is built before requesting focus
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(searchFocusNode);
      }
    });
  }

  void _deactivateSearch() {
    setState(() {
      _isSearchActive = false;
    });
    searchFocusNode.unfocus();
  }

  void _closeSearch() {
    _clearSearch();
    _deactivateSearch();
  }

  void _clearSearch() {
    searchControllerTodo.clear();

    // Check route and clear appropriate search
    String currentRoute = Get.currentRoute;

    if (currentRoute == '/Products') {
      if (app.appController.productsFilterCallback != null) {
        app.appController.productsFilterCallback!('');
      }
    } else if (currentRoute == '/Category') {
      if (app.appController.categoryFilterCallback != null) {
        app.appController.categoryFilterCallback!('');
      }
    }else if (currentRoute == '/StoreCustomer') {
      if (app.appController.customerFilterCallback != null) {
        app.appController.customerFilterCallback!('');
      }
    } else if (app.appController.selectedTabIndex == 0) {
      app.appController.clearSearch();
    } else if (app.appController.selectedTabIndex == 1) {
      app.appController.clearReservationSearch();
    }
  }

  static const double _logoSize = 46;

  // Store logo, rounded only at the bottom corners; tapping it opens the drawer.
  Widget _storeLogo() {
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: ClipRRect(
        // borderRadius: const BorderRadius.only(
        //   bottomLeft: Radius.circular(_logoSize / 2),
        //   bottomRight: Radius.circular(_logoSize / 2),
        // ),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: _logoSize,
          height: _logoSize,
          color: Colors.white,
          child: (_logoUrl ?? '').isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: _logoUrl!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => _logoFallback(),
                )
              : _logoFallback(),
        ),
      ),
    );
  }

  Widget _logoFallback() {
    final name = (_storeName ?? '').trim();
    return Center(
      child: name.isEmpty
          ? const Icon(Icons.storefront_rounded, color: AppTheme.accent)
          : Text(name[0].toUpperCase(),
              style: const TextStyle(fontFamily: 'Sora',
                  fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accent)),
    );
  }

  // Search icon that expands right-to-left into a search field.
  Widget _searchBox(double maxWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      width: _isSearchActive ? maxWidth : 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isSearchActive
          // Laid out at full width and clipped, so the field is revealed
          // right-to-left as the box grows instead of overflowing.
          ? OverflowBox(
              minWidth: maxWidth,
              maxWidth: maxWidth,
              alignment: Alignment.centerRight,
              child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: AppTheme.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchControllerTodo,
                    focusNode: searchFocusNode,
                    style: const TextStyle(fontFamily: 'Sora', fontSize: 14),
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'search_item'.tr,
                      hintStyle: const TextStyle(fontFamily: 'Sora', fontSize: 14, color: Colors.black45),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => searchFocusNode.unfocus(),
                  ),
                ),
                IconButton(
                  onPressed: _closeSearch,
                  icon: const Icon(Icons.close_rounded, color: Colors.black54, size: 20),
                  splashRadius: 18,
                ),
              ],
            ),
            )
          : InkWell(
              onTap: _activateSearch,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(Icons.search_rounded, color: AppTheme.accent, size: 22),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // an app bar never needs bottom inset (would add a gap under it)
      child: Container(
       // margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          // Theme violet → blue → red, dark; text on it is white.
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D3DF0), Color(0xFF4F6DF7), Color(0xFFE5486F)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40)
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Obx(() {
          String currentRoute = Get.currentRoute;
          bool showSearchBox = app.appController.selectedTabIndex == 0 ||
              app.appController.selectedTabIndex == 1 ||
              currentRoute == '/Products' ||
              currentRoute == '/Category' ||
              currentRoute == '/StoreCustomer';
          return LayoutBuilder(builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  children: [
                    _storeLogo(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_greeting()} 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Sora', fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(_storeName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Sora',
                                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                    if (widget.roleId == 1 || widget.roleId == 5)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () {
                            if (widget.roleId == 1) {
                              Get.offAll(() => const SuperAdmin());
                            } else {
                              Get.offAll(() => StoreOwnerStores());
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: AppTheme.accent),
                          ),
                        ),
                      ),
                    // room for the collapsed search button
                    if (showSearchBox) const SizedBox(width: 52),
                  ],
                ),
                if (showSearchBox) _searchBox(constraints.maxWidth - _logoSize - 8),
              ],
            );
          });
        }),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
