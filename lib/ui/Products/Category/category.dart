import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../models/add_new_product_category_response_model.dart';
import '../../../models/iamge_upload_response_model.dart';
import '../../../api/repository/api_repository.dart';
import '../../../constants/constant.dart';
import '../../../customView/CustomAppBar.dart';
import '../../../customView/CustomDrawer.dart';
import '../../../models/edit_existing_product_category_response_model.dart';
import '../../../models/get_added_tax_response_model.dart';
import '../../../models/get_product_category_list_response_model.dart';
import '../../../utils/my_application.dart';
class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  TextEditingController categoryNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? selectedTaxId;
  String? selectedTaxName;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  void _openTab(int index) {
    if (_pageController.hasClients &&
        _pageController.page == index.toDouble()) {
      print("Already on tab $index. Skipping.");
      return;
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
       await getProductCategory();
      getStoreTaxes();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  List<ScrollController> scrollControllers = [];
  int? currentScrolledIndex;
  List<GetProductCategoryList> productCategoryList = [];
  List<getAddedtaxResponseModel> storeTaxesList = [];
  bool isResetting = false;
  bool isEditMode = false;
  GetProductCategoryList? editingCategory;

  List<GetProductCategoryList> filteredCategoryList = [];
  String currentSearchQuery = '';
  int currentPage = 1;
  int itemsPerPage = 8;
  int totalPages = 0;
  List<GetProductCategoryList> currentPageItems = [];

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();

    app.appController.registerCategoryFilter(_filterCategories);


    super.initState();
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'select_image'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Mulish',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Camera Option
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 500,
                        maxHeight: 500,
                        imageQuality: 80,
                      );

                      if (image != null) {
                        setModalState(() {
                          selectedImage = File(image.path);
                        });
                      }
                    } catch (e) {
                      print('Error picking image from camera: $e');
                      Get.snackbar('error'.tr, 'failed_capture'.tr);
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'camera'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
                // Gallery Option
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 500,
                        maxHeight: 500,
                        imageQuality: 80,
                      );

                      if (image != null) {
                        setModalState(() {
                          selectedImage = File(image.path);
                        });
                      }
                    } catch (e) {
                      print('Error picking image from gallery: $e');
                      Get.snackbar('Error', 'Failed to pick image');
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCAE03),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'gallery'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Mulish',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Cancel Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.grey.shade600,
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

  Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return file;

      if (image.width > 1024 || image.height > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      final compressedBytes = img.encodeJpg(image, quality: 70);

      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Compression error: $e');
      return file;
    }
  }

  Future<String?> uploadCategoryImage(File imageFile) async {
    try {
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

      image_upload_response_model response = await CallService().uploadImage(imageFile);

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (response.url != null && response.url!.isNotEmpty) {
        print("Image uploaded successfully: ${response.url}");
        return response.url;
      } else {
        throw Exception('Image URL is empty');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      print('Image upload error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _updatePagination() {
    totalPages = (filteredCategoryList.length / itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredCategoryList.length) endIndex = filteredCategoryList.length;

    currentPageItems = filteredCategoryList.sublist(startIndex, endIndex);
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


  @override
  void dispose() {
    app.appController.categoryFilterCallback = null;
    _pageController.dispose();
    categoryNameController.dispose();
    descriptionController.dispose();
    for (ScrollController controller in scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getTrimmedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // Remove query parameters (everything after '?')
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      return url.substring(0, queryIndex);
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        drawer: CustomDrawer(onSelectTab: _openTab),
        appBar: const CustomAppBar(),
        body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('category'.tr, style: const TextStyle(
                          fontFamily: 'Mulish', fontSize: 18, fontWeight: FontWeight.bold
                      )),
                      GestureDetector(
                        onTap: () {
                          _showAddCategoryBottomSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: const Color(0xFFFCAE03),
                          ),
                          child:  Center(
                            child: Text('add'.tr, style: const TextStyle(
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
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${'showing'.tr} ${(currentPage - 1) * itemsPerPage + 1} to ${(currentPage - 1) * itemsPerPage + currentPageItems.length}'
                            ' of ${filteredCategoryList.length} ${'entries'.tr}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Mulish',
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECF8FF),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(left: 40),
                          child: Row(
                           // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.38,
                                child: Text('name'.tr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily: 'Mulish'
                                  ),
                                ),
                              ),
                              Container(
                                //width: MediaQuery.of(context).size.width * 0.2,
                                child: Text('taxe'.tr,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        fontFamily: 'Mulish'
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Center(
                            child: Text('status'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish'
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  if (isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: const Center(),
                    )
                  else if (filteredCategoryList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        currentSearchQuery.isEmpty ? 'no'.tr : '${'no_categories'.tr} "$currentSearchQuery"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Mulish',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentPageItems.length,
                      itemBuilder: (context, index) {
                        final product = currentPageItems[index];//
                         var productId=product.id.toString();
                         print('Product Id IS$productId');
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            controller: scrollControllers[index], // Add this line
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _getTrimmedImageUrl(product.imageUrl),
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5,),
                                Container(
                                  // width: MediaQuery.of(context).size.width * 0.6,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(product.name.toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  fontFamily: 'Mulish'
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(product.description.toString(),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 10,
                                                  fontFamily: 'Mulish'
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        child: Center(
                                          child: Text(
                                           "${product.tax?.percentage.toString()}%",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                fontFamily: 'Mulish'
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () {
                                    _showStatusChangeDialog(context, product.name.toString(), product.id!, product.isActive ?? false);
                                  },
                                  child: Container(
                                    height: 25,
                                    width: 60,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: (product.isActive == true) ? const Color(0xff49B27A) : const Color(0xffE25454)
                                    ),
                                    child: Center(
                                      child: Text(
                                        (product.isActive == true) ? 'active'.tr : 'inactive'.tr,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Mulish',
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    _showAddCategoryBottomSheet(context, categoryToEdit: product);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xff0C831F)
                                    ),
                                    child: const Center(
                                      child: Icon(
                                          Icons.mode_edit_outline_outlined,
                                          color: Colors.white,
                                          size: 16
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _showDeleteTaxConfirmation(context, product.name.toString(), product.id!);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xffE25454)
                                    ),
                                    child: const Center(
                                      child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                          size: 16
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

                  if (filteredCategoryList.isNotEmpty && totalPages > 1)
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
            )
        )
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
            )
        ),
        barrierDismissible: false,
      );
    }

    try {

      List<GetProductCategoryList> category = showLoader
          ? await _executeWithTimeout(() => CallService().getProductCategory(storeId!))
          : await CallService().getProductCategory(storeId!);

      if (showLoader) {
        Get.back();
      }

      if (mounted) {
        setState(() {
          productCategoryList = category;
          filteredCategoryList = category;
          currentPage = 1;
          _updatePagination();
          print('category list length is ${filteredCategoryList.length}');

          scrollControllers = List.generate(currentPageItems.length, (index) {
            ScrollController controller = ScrollController();
            controller.addListener(() {
              // Skip if we're programmatically resetting
              if (isResetting) return;

              // When this container is scrolled left
              if (controller.offset > 10) {
                // Reset previous container if different
                if (currentScrolledIndex != null && currentScrolledIndex != index) {
                  isResetting = true; // Set flag before animating

                  if (scrollControllers[currentScrolledIndex!].hasClients) {
                    scrollControllers[currentScrolledIndex!].animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    ).then((_) {
                      isResetting = false; // Reset flag after animation
                    });
                  } else {
                    isResetting = false;
                  }
                }
                // Set this as current
                currentScrolledIndex = index;
              }
            });
            return controller;
          });
          isLoading = false;
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

  void _filterCategories(String query) {
    setState(() {
      currentSearchQuery = query.toLowerCase();
      if (currentSearchQuery.isEmpty) {
        filteredCategoryList = productCategoryList;
      } else {
        filteredCategoryList = productCategoryList.where((category) {
          final name = category.name?.toLowerCase() ?? '';
          final description = category.description?.toLowerCase() ?? '';
          final tax = category.tax?.name?.toLowerCase() ?? '';

          return name.contains(currentSearchQuery) ||
              description.contains(currentSearchQuery) ||
              tax.contains(currentSearchQuery);
        }).toList();
      }

      currentPage = 1;
      _updatePagination();

      // ✅ CRITICAL FIX: Dispose old controllers before creating new ones
      for (ScrollController controller in scrollControllers) {
        controller.dispose();
      }
      scrollControllers.clear();

      // ✅ Create scroll controllers for FILTERED list
      scrollControllers = List.generate(currentPageItems.length, (index) {
        ScrollController controller = ScrollController();
        controller.addListener(() {
          if (isResetting) return;

          if (controller.offset > 10) {
            if (currentScrolledIndex != null && currentScrolledIndex != index) {
              isResetting = true;

              if (currentScrolledIndex! < scrollControllers.length &&
                  scrollControllers[currentScrolledIndex!].hasClients) {
                scrollControllers[currentScrolledIndex!].animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                ).then((_) {
                  isResetting = false;
                });
              } else {
                isResetting = false;
              }
            }
            currentScrolledIndex = index;
          }
        });
        return controller;
      });
    });

    print("🔍 Categories filtered: ${filteredCategoryList.length} results");
  }

  void _showAddCategoryBottomSheet(BuildContext context, {GetProductCategoryList? categoryToEdit}) {
    // Set edit mode and prefill data if editing
    if (categoryToEdit != null) {
      isEditMode = true;
      editingCategory = categoryToEdit;
      categoryNameController.text = categoryToEdit.name ?? '';
      descriptionController.text = categoryToEdit.description ?? '';
      selectedTaxId = categoryToEdit.tax?.id?.toString();
      selectedTaxName = '${categoryToEdit.tax?.name} (${categoryToEdit.tax?.percentage}%)';
      // Handle image URL if needed
      selectedImage = null; // Reset for now, you can implement image loading if needed
    } else {
      isEditMode = false;
      editingCategory = null;
      // Clear fields for add mode
      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Stack(clipBehavior: Clip.none,
            children: [
              Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Centered Title
                      Center(
                        child: Text(
                          isEditMode ? 'edit'.tr : 'new'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                          ),
                        ),
                      ),
                      // Image Button in Top Right
                      Positioned(
                        right: 0,
                        top: -5,
                        child: GestureDetector(
                          onTap: () {
                            _pickImage(setModalState);
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (selectedImage != null || (isEditMode && editingCategory?.imageUrl != null && editingCategory!.imageUrl!.isNotEmpty))
                                  ? Colors.transparent
                                  : const Color(0xFFFCAE03),
                              border: (selectedImage != null || (isEditMode && editingCategory?.imageUrl != null && editingCategory!.imageUrl!.isNotEmpty))
                                  ? Border.all(color: Colors.grey.shade300, width: 2)
                                  : null,
                            ),
                            child: selectedImage != null
                                ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22.5),
                                  child: Image.file(
                                    selectedImage!,
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Close Icon
                                Positioned(
                                  top: 0,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        selectedImage = null;
                                      });
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : (isEditMode && editingCategory?.imageUrl != null && editingCategory!.imageUrl!.isNotEmpty)
                                ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22.5),
                                  child: CachedNetworkImage(
                                    imageUrl: _getTrimmedImageUrl(editingCategory!.imageUrl),
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                // Close Icon for existing image
                                Positioned(
                                  top: 0,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        // Clear the existing image
                                        editingCategory!.imageUrl = null;
                                      });
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'category_name'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryNameController,
                    decoration: InputDecoration(
                      hintText: 'add_category'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontFamily: 'Mulish',
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
                        borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tax Dropdown
                  Text(
                    'select'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedTaxId,
                      hint: Text(
                        'select'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontFamily: 'Mulish',
                        ),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      ),
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                      items: storeTaxesList.map<DropdownMenuItem<String>>((tax) {
                        return DropdownMenuItem<String>(
                          value: tax.id.toString(),
                          child: Text(
                            '${tax.name} (${tax.percentage}%)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Mulish',
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          selectedTaxId = newValue;
                          // Find selected tax name for display
                          var selectedTax = storeTaxesList.firstWhere((tax) => tax.id.toString() == newValue);
                          selectedTaxName = '${selectedTax.name} (${selectedTax.percentage}%)';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description Field
                  Text(
                    'desc'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintText: 'description'.tr,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontFamily: 'Mulish',
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
                        borderSide: const BorderSide(color: Color(0xFFFCAE03)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            categoryNameController.clear();
                            descriptionController.clear();
                            selectedTaxId = null;
                            selectedTaxName = null;
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                'cancel'.tr,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Mulish',
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Save Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            String categoryName = categoryNameController.text.trim();
                            String description = descriptionController.text.trim();

                            // ✅ Pehle validate karo
                            if (categoryName.isEmpty) {
                              Get.snackbar('error'.tr, 'please_category'.tr);
                              return;
                            }

                            if (selectedTaxId == null) {
                              Get.snackbar('error'.tr, 'please_tax'.tr);
                              return;
                            }

                            print('Category Name: $categoryName');
                            print('Selected Tax ID: $selectedTaxId');
                            print('Description: $description');

                            // ✅ Baad mein API call karo
                            if (isEditMode) {
                              _updateProductCategory(editingCategory!.id.toString());
                            } else {
                              _saveProductCategory();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFFCAE03),
                            ),
                            child: Center(
                              child: Text(
                                isEditMode ? 'update'.tr : 'saved'.tr,
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
              Positioned(
                top: -20,
                right: 0,
                left: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
        ),
      ),
    );
  }

  Future<void> getStoreTaxes({bool showLoader = true}) async {
    if (sharedPreferences == null) {
      print('SharedPreferences not initialized yet');
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);

    if (storeId == null) {
      print('Store ID not found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (showLoader) {
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
            )
        ),
        barrierDismissible: false,
      );
    }

    try {
      List<getAddedtaxResponseModel> storeTax = showLoader
          ? await _executeWithTimeout(() => CallService().getStoreTax(storeId!))
          : await CallService().getStoreTax(storeId!);

      if (showLoader) {
        Get.back();
      }

      setState(() {
        storeTaxesList=storeTax;
        isLoading = false;
      });

    } catch (e) {
      if (showLoader) {
        Get.back();
      }
      print('Error getting Store taxes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProductCategory() async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }
    try {
      String? uploadedImageUrl;
      if (selectedImage != null) {
        uploadedImageUrl = await uploadCategoryImage(selectedImage!);
        if (uploadedImageUrl == null) {
          return; // Exit if image upload failed
        }
      }

      var map = {
        "name": categoryNameController.text.trim(),
        "store_id": storeId,
        "tax_id": selectedTaxId,
        "image_url": uploadedImageUrl ?? "",
        "description": descriptionController.text.trim()
      };

      print("Add product Map: $map");

      AddNewProductCategoryResponseModel model = await _executeWithTimeout(
              () => CallService().addNewProductCategory(map)
      );
      print("Product Category added successfully");

      // Clear form fields
      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;
      await getProductCategory(showLoader: false);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('product_category'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      // Close loader on error
      Get.back();

      print('Adding error: $e');

      // Show error using ScaffoldMessenger
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'failed_category'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<T> _executeWithTimeout<T>(
      Future<T> Function() apiCall,
      {Duration timeout = const Duration(seconds: 7)}
      ) async
  {
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
      final result = await apiCall().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );
      if (Get.isDialogOpen ?? false) {
        Navigator.of(Get.overlayContext!).pop();
      }
      return result;
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Navigator.of(Get.overlayContext!).pop();
      }
      rethrow;
    }
  }

  void _showDeleteTaxConfirmation(BuildContext context, String productName, int productId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                // margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    const SizedBox(height: 20,),
                    Text(
                      '${'are'.tr}"$productName"?',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          fontFamily: 'Mulish'
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
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
                            child:  Text(
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
                              _deleteProductCategory(productId);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child:  Text(
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
                ),)
            ]
        ),
      ),
    );
  }

  Future<void> _deleteProductCategory(int productId) async {
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
      print('API call ProductId: $productId ke liye');

      await _executeWithTimeout(() => CallService().deleteProductCategory(productId));
      await getProductCategory(showLoader: false);
      Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('category_delete'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {

      Get.back();

      print('Error deleting product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_category_delete'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _updateProductCategory(String productId) async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }

    // Show loader
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
      String? finalImageUrl = editingCategory?.imageUrl; // Keep existing URL

      // Upload new image if selected
      if (selectedImage != null) {
        String? uploadedImageUrl = await uploadCategoryImage(selectedImage!);
        if (uploadedImageUrl == null) {
          return; // Exit if image upload failed
        }
        finalImageUrl = uploadedImageUrl;
      }

      var map = {
        "name": categoryNameController.text.trim(),
        "store_id": storeId,
        "tax_id": selectedTaxId,
        "image_url": finalImageUrl ?? "",
        "description": descriptionController.text.trim()
      };

      print("Edit Product Category Map: $map");

      EditExistingProductCategoryResponseModel model = await _executeWithTimeout(
              () => CallService().editProductCategory(map, productId)
      );

      print("Product updated successfully");

      categoryNameController.clear();
      descriptionController.clear();
      selectedTaxId = null;
      selectedTaxName = null;
      selectedImage = null;

      await getProductCategory(showLoader: false);
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('category_update'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      // Close loader on error
      if (Get.isDialogOpen ?? false) {
        Navigator.of(Get.overlayContext!).pop();
      }

      print('Edit error: $e');

      // Show error using ScaffoldMessenger
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'upd_category'.tr}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showStatusChangeDialog(BuildContext context, String categoryName, int categoryId, bool currentStatus) {
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
                      currentStatus
                          ? '${'deactivate_cat'.tr} "$categoryName"?'
                          : '${'reactivate_cat'.tr} "$categoryName"?',
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
                            color: currentStatus ? const Color(0xFFE25454) : const Color(0xff49B27A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                              _toggleCategoryStatus(categoryId, !currentStatus);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            child: Text(
                              'yes'.tr,
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

  Future<void> _toggleCategoryStatus(int categoryId, bool newStatus) async {
    if (sharedPreferences == null) {
      Get.snackbar('error'.tr, 'shared'.tr);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      Get.snackbar('error'.tr, 'storeId'.tr);
      return;
    }

    // Find the category to get its current data
    GetProductCategoryList? category = productCategoryList.firstWhere(
          (cat) => cat.id == categoryId,
      orElse: () => GetProductCategoryList(),
    );

    if (category.id == null) {
      Get.snackbar('error'.tr, 'category_not_found'.tr);
      return;
    }

    // Show loader
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
      // Prepare map with existing data + updated isActive status
      var map = {
        "name": category.name ?? '',
        "store_id": storeId,
        "tax_id": category.tax?.id?.toString() ?? '',
        "image_url": category.imageUrl ?? "",
        "description": category.description ?? '',
        "isActive": newStatus,
      };

      print("Toggle Status Map: $map");

      EditExistingProductCategoryResponseModel model = await _executeWithTimeout(
              () => CallService().editProductCategory(map, categoryId.toString())
      );

      // Refresh category list
      await getProductCategory(showLoader: false);

      // Close loader
      Get.back();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'category_activated'.tr : 'category_deactivated'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      // Close loader on error
      Get.back();

      print('Error toggling status: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_status_change'.tr),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
}
