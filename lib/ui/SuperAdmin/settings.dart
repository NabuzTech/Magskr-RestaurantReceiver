import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../models/get_admin_report_response_model.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isLoading = false;
  List<Reports> stores = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStores());
  }

  Future<void> _loadStores() async {
    setState(() => isLoading = true);
    try {
      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );
      final model = await CallService().getAdminReportAllStore();
      setState(() => stores = model.reports ?? []);
      if (Get.isDialogOpen ?? false) Get.back();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Failed to load stores', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<String, Color> _storeColors(int? storeId) {
    switch (storeId) {
      case 12: return {'border': const Color(0xff029543), 'background': const Color(0xffEBFAF2), 'nameColor': const Color(0xff029543)};
      case 13: return {'border': const Color(0xffE4121E), 'background': const Color(0xffFCF6F7), 'nameColor': const Color(0xffE4121E)};
      case 14: return {'border': const Color(0xff841D1C), 'background': const Color(0xffF6EDED), 'nameColor': const Color(0xff841D1C)};
      case 15: return {'border': const Color(0xff023047), 'background': const Color(0xffFAFDFF), 'nameColor': const Color(0xff023047)};
      case 16: return {'border': const Color(0xff624BA1), 'background': const Color(0x0ffdfcff), 'nameColor': const Color(0xff624BA1)};
      case 18: return {'border': const Color(0xffE0D2AA), 'background': const Color(0xffFAF3E0), 'nameColor': const Color(0xffE64425)};
      case 19: return {'border': const Color(0xffF9CC46), 'background': const Color(0xffFDFAF1), 'nameColor': const Color(0xff029447)};
      case 20: return {'border': const Color(0xffE31E22), 'background': const Color(0xffFFDCDD), 'nameColor': const Color(0xffE31E22)};
      case 21: return {'border': const Color(0xff0D9488), 'background': const Color(0xffF0FDFA), 'nameColor': const Color(0xff0D9488)};
      case 22: return {'border': const Color(0xffEA580C), 'background': const Color(0xffFFF7ED), 'nameColor': const Color(0xffEA580C)};
      case 23: return {'border': const Color(0xff4338CA), 'background': const Color(0xffEEF2FF), 'nameColor': const Color(0xff4338CA)};
      case 24: return {'border': const Color(0xffDB2777), 'background': const Color(0xffFDF2F8), 'nameColor': const Color(0xffDB2777)};
      case 25: return {'border': const Color(0xff4D7C0F), 'background': const Color(0xffF7FEE7), 'nameColor': const Color(0xff4D7C0F)};
      case 26: return {'border': const Color(0xff0E7490), 'background': const Color(0xffECFEFF), 'nameColor': const Color(0xff0E7490)};
      case 27: return {'border': const Color(0xffBE123C), 'background': const Color(0xffFFF1F2), 'nameColor': const Color(0xffBE123C)};
      case 28: return {'border': const Color(0xffB45309), 'background': const Color(0xffFEF3C7), 'nameColor': const Color(0xffB45309)};
      case 29: return {'border': const Color(0xff047857), 'background': const Color(0xffECFDF5), 'nameColor': const Color(0xff047857)};
      case 30: return {'border': const Color(0xff6D28D9), 'background': const Color(0xffF5F3FF), 'nameColor': const Color(0xff6D28D9)};
      case 31: return {'border': const Color(0xff0369A1), 'background': const Color(0xffF0F9FF), 'nameColor': const Color(0xff0369A1)};
      case 32: return {'border': const Color(0xffA21CAF), 'background': const Color(0xffFDF4FF), 'nameColor': const Color(0xffA21CAF)};
      case 33: return {'border': const Color(0xff78350F), 'background': const Color(0xffFDF6EC), 'nameColor': const Color(0xff78350F)};
      case 34: return {'border': const Color(0xff475569), 'background': const Color(0xffF8FAFC), 'nameColor': const Color(0xff475569)};
      default: return {'border': const Color(0xffE0D2AA), 'background': Colors.white, 'nameColor': const Color(0xffE64425)};
    }
  }

  void _showResetPasswordDialog(Reports store) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Reset Password',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, fontFamily: 'Mulish', color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.storeName ?? '',
                          style: const TextStyle(fontSize: 12, fontFamily: 'Mulish', color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        // Password field
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscure,
                          style: const TextStyle(fontFamily: 'Mulish', fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: const TextStyle(fontFamily: 'Mulish', fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.green, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            suffixIcon: IconButton(
                              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey),
                              onPressed: () => setDialogState(() => obscure = !obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Password cannot be empty';
                            if (v.trim().length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Cancel
                            TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            // Save
                            ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                Get.back();
                                await _resetPassword(store, passwordController.text.trim());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: const Text('Save', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Close icon
                Positioned(
                  top: -14,
                  right: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFFED4C5C), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(Reports store) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, fontFamily: 'Mulish', color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.storeName ?? '',
                          style: const TextStyle(fontSize: 12, fontFamily: 'Mulish', color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 18),
                        Text('Are You Sure You Want To LogOut \n Store ${store.storeName}',
                          style: const TextStyle(fontSize: 12, fontFamily: 'Mulish', color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Cancel
                            TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            // Save
                            ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                Get.back();
                                await logoutStore(store,store.storeId.toString());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              child: const Text('Logout', style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Close icon
                Positioned(
                  top: -14,
                  right: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFFED4C5C), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _resetPassword(Reports store, String newPassword) async {
    try {
      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );

      await CallService().resetPassword({'new_password': newPassword}, store.storeId.toString());

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Success',
        'Password reset for ${store.storeName}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Failed to reset password',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> logoutStore(Reports store, String storeId) async {
    try {
      Get.dialog(
        Center(child: Lottie.asset('assets/animations/burger.json', width: 150, height: 150, repeat: true)),
        barrierDismissible: false,
      );

      await CallService().logOutStoreBySuperAdmin({},store.storeId.toString());

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Success',
        'Store ${store.storeName} Logged Out Successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Failed to Close Store',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.arrow_back_ios, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Mulish', fontSize: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Store list
          Expanded(
            child: isLoading
                ? const SizedBox()
                : stores.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_outlined, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('No stores found', style: TextStyle(fontFamily: 'Mulish', fontSize: 14, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          final colors = _storeColors(store.storeId);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: colors['background'],
                              border: Border.all(color: colors['border']!, width: 1.2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID : ${store.storeId}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Mulish', color: Colors.black54),
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width*0.4,
                                      child: Text(
                                        store.storeName ?? '',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Mulish', color: colors['nameColor']),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: InkWell(
                                        onTap: () => _showResetPasswordDialog(store),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Reset Password',
                                              style: TextStyle(fontSize: 13, fontFamily: 'Mulish', fontWeight: FontWeight.w600, color: colors['nameColor']),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.lock_reset_outlined, color: colors['nameColor'], size: 18),
                                          ],
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: InkWell(
                                        onTap: () => _showLogoutDialog(store),
                                        child: Row(
                                          children: [
                                            Text(
                                              'LogOut',
                                              style: TextStyle(fontSize: 13, fontFamily: 'Mulish', fontWeight: FontWeight.w600, color: colors['nameColor']),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(Icons.logout_outlined, color: colors['nameColor'], size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
