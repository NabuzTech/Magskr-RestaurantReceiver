import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/repository/api_repository.dart';
import '../../constants/constant.dart';
import '../../models/add_tax_response_mode.dart';
import '../../models/edit_tax_response_model.dart';

class AddTaxBottomSheet extends StatefulWidget {
  final VoidCallback? onDataAdded;
  final String? editTaxName;
  final String? editTaxPercentage;
  final int? editTaxId;
  final bool isEditMode;

  const AddTaxBottomSheet({
    super.key,
    this.onDataAdded,
    this.editTaxName,
    this.editTaxPercentage,
    this.editTaxId,
    this.isEditMode = false,
  });

  @override
  State<AddTaxBottomSheet> createState() => _AddTaxBottomSheetState();
}

class _AddTaxBottomSheetState extends State<AddTaxBottomSheet> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _taxPercentageController = TextEditingController();

  bool isLoading = false;
  String? storeId;
  SharedPreferences? sharedPreferences;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
    if (widget.isEditMode) {
      _prefillEditData();
    }
  }

  Future<void> _initializeSharedPreferences() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
    }
  }

  void _prefillEditData() {
    setState(() {
      if (widget.editTaxName != null) {
        _taxNameController.text = widget.editTaxName!;
      }
      if (widget.editTaxPercentage != null) {
        _taxPercentageController.text = widget.editTaxPercentage!;
      }
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSave() {
    if (_taxNameController.text.trim().isEmpty) {
      _showSnackbar('enter_tax'.tr, isError: true);
      return;
    }

    if (_taxPercentageController.text.trim().isEmpty) {
      _showSnackbar('enter_percentage'.tr, isError: true);
      return;
    }

    double? percentage = double.tryParse(_taxPercentageController.text.trim());
    if (percentage == null) {
      _showSnackbar('valid_percentage'.tr, isError: true);
      return;
    }

    if (percentage < 0 || percentage > 100) {
      _showSnackbar('tax_percentage'.tr, isError: true);
      return;
    }

    if (widget.isEditMode) {
      _editSavedTax();
    } else {
      _saveTax();
    }
  }

  Future<void> _saveTax() async {
    if (sharedPreferences == null) {
      _showSnackbar('shared'.tr, isError: true);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      _showSnackbar('storeId'.tr, isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Show loading dialog
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
      var map = {
        "name": _taxNameController.text.trim(),
        "percentage": double.parse(_taxPercentageController.text.trim()),
        "store_id": storeId
      };

      print("Add Tax Map: $map");

      AddTaxResponseModel model = await CallService().addStoreTaxes(map);

      print("Tax added successfully");

      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        isLoading = false;
      });

      // Close bottom sheet
      if (mounted) {
        Navigator.pop(context);
      }

      // Call callback to refresh list
      if (widget.onDataAdded != null) {
        widget.onDataAdded!();
      }

      // Small delay then show success message
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        _showSnackbar('tax_add'.tr);
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        isLoading = false;
      });

      print('Adding error: $e');

      if (mounted) {
        _showSnackbar('${'failed_tax_add'.tr}: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _editSavedTax() async {
    if (sharedPreferences == null) {
      _showSnackbar('shared'.tr, isError: true);
      return;
    }

    storeId = sharedPreferences!.getString(valueShared_STORE_KEY);
    if (storeId == null) {
      _showSnackbar('storeId'.tr, isError: true);
      return;
    }

    if (widget.editTaxId == null) {
      _showSnackbar('tax_id'.tr, isError: true);
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Show loading dialog using showDialog instead of Get.dialog
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
      var map = {
        "name": _taxNameController.text.trim(),
        "percentage": double.parse(_taxPercentageController.text.trim()),
        "store_id": storeId
      };

      print("Edit Tax Map: $map");

      editTaxResponseModel model = await CallService().editStoreTaxes(
          map, widget.editTaxId.toString());

      print("Tax updated successfully");

      // Close loading dialog using Navigator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        isLoading = false;
      });

      // Close bottom sheet
      if (mounted) {
        Navigator.pop(context);
      }

      // Call callback to refresh list
      if (widget.onDataAdded != null) {
        widget.onDataAdded!();
      }

      // Small delay then show success message
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        _showSnackbar('tax_upd'.tr);
      }

    } catch (e) {
      // Close loading dialog using Navigator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      setState(() {
        isLoading = false;
      });

      print('Edit error: $e');

      if (mounted) {
        _showSnackbar('${'tax_failed'.tr}: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.isEditMode ? 'edit_tax'.tr : 'add_tax'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Mulish',
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'tax_name'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taxNameController,
                    decoration: InputDecoration(
                      hintText: 'enter'.tr,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Mulish',
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'percentage'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taxPercentageController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'enter_percent'.tr,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Mulish',
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          '%',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff757B8F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'cancel'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'saved'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Mulish',
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
          ),
        ),
        Positioned(
          top: -90,
          right: 0,
          left: 0,
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(15),
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
                child: const Icon(Icons.close, size: 30, color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void showAddTaxBottomSheet(
    BuildContext context, {
      VoidCallback? onDataAdded,
      String? editTaxName,
      String? editTaxPercentage,
      int? editTaxId,
      bool isEditMode = false,
    }) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddTaxBottomSheet(
        onDataAdded: onDataAdded,
        editTaxName: editTaxName,
        editTaxPercentage: editTaxPercentage,
        editTaxId: editTaxId,
        isEditMode: isEditMode,
      ),
    ),
  );
}