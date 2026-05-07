import 'package:flutter/material.dart';
import 'package:food_receiver/ui/Tax%20MAnagement/tax_bottomsheet.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/CustomDrawer.dart';
import '../../models/get_added_tax_response_model.dart';

class Taxmanagement extends StatefulWidget {
  const Taxmanagement({super.key});

  @override
  State<Taxmanagement> createState() => _TaxmanagementState();
}

class _TaxmanagementState extends State<Taxmanagement> {
  late PageController _pageController;
  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;
  List<getAddedtaxResponseModel> storeTaxesList = [];

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
      await getStoreTaxes();
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _initializeSharedPreferences();
    super.initState();
  }

  void _showSnackbar(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;

    Color backgroundColor = Colors.green;
    if (isError) {
      backgroundColor = Colors.red;
    } else if (isWarning) {
      backgroundColor = Colors.orange;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isWarning ? 4 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  Text('manage'.tr,
                      style: const TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      showTaxManagementBottomSheet(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFECF8FF),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'tax_name'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                fontFamily: 'Mulish'),
                          ),
                          Text('percent'.tr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'Mulish')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: Center(
                        child: Text(
                          'action'.tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Mulish'),
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
              else if (storeTaxesList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'No taxes found',
                    style: TextStyle(
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
                  itemCount: storeTaxesList.length,
                  itemBuilder: (context, index) {
                    final tax = storeTaxesList[index];
                    var taxid = tax.id.toString();
                    print('taxId is$taxid');
                    print('value is${tax.percentage}');
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
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: Text(
                                      tax.name ?? 'Unknown Tax',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          fontFamily: 'Mulish'),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width * 0.2,
                                    child: Center(
                                      child: Text(
                                        '${tax.percentage?.toStringAsFixed(2) ?? '0.000'}%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            fontFamily: 'Mulish'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(
                              onTap: () {
                                showEditTaxBottomSheet(context, tax);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xff0C831F)),
                                child: const Center(
                                  child: Icon(Icons.mode_edit_outline_outlined,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (tax.id != null) {
                                  _showDeleteTaxConfirmation(
                                      context, tax.name ?? 'Tax', tax.id!);
                                } else {
                                  _showSnackbar('taxId'.tr, isError: true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xffE25454)),
                                child: const Center(
                                  child: Icon(Icons.delete_outline,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showTaxManagementBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaxBottomSheet(
          onDataAdded: () async {
            await getStoreTaxes(showLoader: false);
          },
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Lottie.asset(
                'assets/animations/burger.json',
                width: 150,
                height: 150,
                repeat: true,
              ),
            ),
          );
        },
      );
    }

    try {
      List<getAddedtaxResponseModel> storeTax =
      await CallService().getStoreTax(storeId!);

      if (showLoader && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        storeTaxesList = storeTax;
        isLoading = false;
      });
    } catch (e) {
      if (showLoader && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      print('Error getting Store taxes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteTaxConfirmation(
      BuildContext context, String taxName, int taxId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => true,
          child: Dialog(
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
                        '${'are'.tr} "$taxName"?',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            fontFamily: 'Mulish'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: Container(
                                height: 35,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8E9AAF),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _deleteTax(taxId);
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: Container(
                                height: 35,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE25454),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Text(
                                    'delete'.tr,
                                    style: const TextStyle(
                                      fontSize: 13,
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
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -20,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                    },
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteTax(int taxId) async {
    print('Delete method me ayi taxId: $taxId');
    print('TaxId type: ${taxId.runtimeType}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            ),
          ),
        );
      },
    );

    try {
      print('API call kar rahe hain taxId: $taxId ke liye');

      await CallService().deleteStoreTax(taxId);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Refresh list
      await getStoreTaxes(showLoader: false);

      // Small delay before showing snackbar
      await Future.delayed(const Duration(milliseconds: 500));

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('tax_delete'.tr),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Error deleting tax: $e');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (e.toString().contains('Cannot delete tax') ||
            e.toString().contains('referenced by')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('this'.tr),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('delete_tax'.tr),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void showEditTaxBottomSheet(
      BuildContext context, getAddedtaxResponseModel tax) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaxBottomSheet(
          onDataAdded: () async {
            await getStoreTaxes(showLoader: false);
          },
          editTaxName: tax.name,
          editTaxPercentage: tax.percentage?.toString(),
          editTaxId: tax.id,
          isEditMode: true,
        ),
      ),
    );
  }
}