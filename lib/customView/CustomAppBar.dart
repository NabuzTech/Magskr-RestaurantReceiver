import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:food_receiver/ui/SuperAdmin/super_admin.dart';

import 'package:get/get.dart';

import '../utils/my_application.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final int? roleId;

  const CustomAppBar({super.key, this.roleId});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _CustomAppBarState extends State<CustomAppBar> {
  TextEditingController searchControllerTodo = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool _showClearButton = false;
  bool _isSearchActive = false;
  String get currentSearchQuery => searchControllerTodo.text;
  @override
  void initState() {
    super.initState();
    searchControllerTodo.addListener(_onSearchTextChanged);
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

    setState(() {
      _showClearButton = searchText.isNotEmpty;
    });

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

  void _handleSearchTap() {
    if (!searchFocusNode.hasFocus) {
      FocusScope.of(context).requestFocus(searchFocusNode);
    }
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

  Widget _buildSearchBox() {
    if (!_isSearchActive) {
      return GestureDetector(
        onTap: _activateSearch,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    searchControllerTodo.text.isEmpty
                        ? 'search_item'.tr
                        : searchControllerTodo.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: searchControllerTodo.text.isEmpty
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              if (searchControllerTodo.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearch,
                  child: const Icon(Icons.clear, color: Colors.grey, size: 18),
                ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchControllerTodo,
                focusNode: searchFocusNode,
                autofocus: false,
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'search_item'.tr,
                  hintStyle: const TextStyle(fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
                onSubmitted: (value) {
                  _deactivateSearch();
                },
                onEditingComplete: () {
                  _deactivateSearch();
                },
              ),
            ),
            if (_showClearButton)
              GestureDetector(
                onTap: _clearSearch,
                child: const Icon(Icons.clear, color: Colors.grey, size: 18),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _deactivateSearch,
              child: const Icon(Icons.keyboard_hide, color: Colors.grey, size: 18),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: SvgPicture.asset('assets/images/drawer.svg')
            ),
            const SizedBox(width: 8),
            Obx(() {
              String currentRoute = Get.currentRoute;
              bool showSearchBox = app.appController.selectedTabIndex == 0 ||
                  app.appController.selectedTabIndex == 1 ||
                  currentRoute == '/Products' ||
                  currentRoute == '/Category';
              currentRoute == '/StoreCustomer';
              if (showSearchBox) {
                return Expanded(child: _buildSearchBox());
              } else {
                return const Expanded(child: SizedBox.shrink());
              }
            }),
            const SizedBox(width: 12),

            if (widget.roleId == 1)
              GestureDetector(
                onTap: (){
                  Get.offAll(()=>const SuperAdmin());
                },
                child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_ios, size: 16,)
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
