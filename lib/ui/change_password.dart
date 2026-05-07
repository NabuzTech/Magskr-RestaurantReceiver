import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../customView/custom_button.dart';
import '../../customView/custom_text_form_prefiex.dart';
import '../../models/change_password_model.dart';
import '../../utils/validators.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;


  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void showSnackbar(String title, String message, {Color? backgroundColor}) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor ?? Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text.trim();

    try {
      Get.dialog(
        Center(
          child: Lottie.asset(
            'assets/animations/burger.json',
            width: 150,
            height: 150,
            repeat: true,
          ),
        ),
        barrierDismissible: false,
      );

      var body = {
        "old_password": _oldPasswordController.text.trim(),
        "new_password": newPass,
      };

      print("Change Password Body: $body");

      ChangePasswordModel model = await CallService().changePassword(body);

      if (Get.isDialogOpen == true) Get.back();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && context.mounted) {
        showSnackbar(
          'success'.tr,
          'password_changed_successfully'.tr,
          backgroundColor: Colors.green,
        );
        Get.back();
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      print('Change password error: $e');
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && context.mounted) {
        showSnackbar('error'.tr, '${'change_password_failed'.tr}: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'change_password'.tr,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 30),

                // Form
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      // Old Password
                      CustomTextFormPrefix(
                        keyboardType: TextInputType.visiblePassword,
                        myLabelText: 'old_password'.tr,
                        controller: _oldPasswordController,
                        icon: const Icon(Icons.lock_outline, color: Colors.black),
                        validate: (value) => validateFieldCustomText(
                          value,
                          'please_enter_old_password'.tr,
                        ),
                        valueChanged: (value) {},
                        obscureText: !_isOldPasswordVisible,
                        isPasswordField: true,
                        isPasswordVisible: _isOldPasswordVisible,
                        onTogglePassword: () {
                          setState(() => _isOldPasswordVisible = !_isOldPasswordVisible);
                        },
                      ),
                      // New Password
                      CustomTextFormPrefix(
                        keyboardType: TextInputType.visiblePassword,
                        myLabelText: 'new_password'.tr,
                        controller: _newPasswordController,
                        icon: const Icon(Icons.lock_reset_outlined, color: Colors.black),
                        validate: (value) => validateFieldCustomText(
                          value,
                          'please_enter_new_password'.tr,
                        ),
                        valueChanged: (value) {},
                        obscureText: !_isNewPasswordVisible,
                        isPasswordField: true,
                        isPasswordVisible: _isNewPasswordVisible,
                        onTogglePassword: () {
                          setState(() => _isNewPasswordVisible = !_isNewPasswordVisible);
                        },
                      ),

                      // Match indicato
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Button
                CustomButton(
                  onPressed: () => changePassword(),
                  myText: 'update_password'.tr,
                  color: Colors.black,
                  textColor: Colors.white,
                  fontSize: 17,
                  fontWeigt: FontWeight.w700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}







