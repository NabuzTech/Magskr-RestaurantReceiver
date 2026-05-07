import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../customView/custom_button.dart';
import '../../customView/custom_text_form_prefiex.dart';
import '../../utils/validators.dart';
import 'loginController.dart';

class DesktopLoginScreen extends StatelessWidget {
  const DesktopLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        actions: [
          _buildEnvironmentDropdown(controller),
          _buildLanguageDropdown(controller),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 600,
            constraints: const BoxConstraints(
              maxWidth: 600,
              minWidth: 400,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLoginTitle(),
                const SizedBox(height: 40),
                _buildLoginForm(controller),
                const SizedBox(height: 20),
                _buildForgotPasswordButton(controller),
                const SizedBox(height: 30),
                _buildLoginButton(controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentDropdown(LoginController controller) {
    return Obx(
          () => Container(
        margin: const EdgeInsets.only(right: 12.0),
        child: DropdownButton<String>(
          value: controller.selectedEnvironment.value,
          underline: const SizedBox(),
          icon: const Icon(Icons.security_rounded, color: Colors.black),
          isDense: true,
          selectedItemBuilder: (BuildContext context) {
            return [
              const Text('Prod', style: TextStyle(fontSize: 16, color: Colors.black)),
              const Text('Test', style: TextStyle(fontSize: 16, color: Colors.black)),
            ];
          },
          items: const [
            DropdownMenuItem(
              value: 'Prod',
              child: Text('Prod', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'Test',
              child: Text('Test', style: TextStyle(fontSize: 16)),
            ),
          ],
          onChanged: (value) {
            if (value != null) controller.changeEnvironment(value);
          },
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(LoginController controller) {
    return Obx(
          () => Container(
        margin: const EdgeInsets.only(right: 12.0),
        child: DropdownButton<String>(
          value: controller.selectedLanguage.value,
          underline: const SizedBox(),
          icon: const Icon(Icons.language, color: Colors.black),
          isDense: true,
          selectedItemBuilder: (BuildContext context) {
            return const [
              Text('English', style: TextStyle(fontSize: 16)),
              Text('German', style: TextStyle(fontSize: 16)),
              Text('India', style: TextStyle(fontSize: 16)),
              Text('CHF', style: TextStyle(fontSize: 16)),
            ];
          },
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'de',
              child: Text('German', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'hi',
              child: Text('India', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'ch',
              child: Text('CHF', style: TextStyle(fontSize: 16)),
            ),
          ],
          onChanged: (value) {
            if (value != null) controller.changeLanguage(value);
          },
        ),
      ),
    );
  }

  Widget _buildLoginTitle() {
    return const Text(
      "Login",
      style: TextStyle(
        fontSize: 36,
        color: Colors.black,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLoginForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Username Field
          SizedBox(
            width: double.infinity,
            height: 65,
            child: CustomTextFormPrefix(
              keyboardType: TextInputType.emailAddress,
              myLabelText: "Username",
              controller: controller.emailController,
              icon: const Icon(Icons.person, color: Colors.black87),
              validate: (value) => validateFieldCustomText(
                value,
                "Please enter username",
              ),
              valueChanged: (value) {},
              obscureText: false,
            ),
          ),
          const SizedBox(height: 20),
          // Password Field
          Obx(
                () => SizedBox(
              width: double.infinity,
              height: 65,
              child: CustomTextFormPrefix(
                keyboardType: TextInputType.visiblePassword,
                myLabelText: "Password",
                controller: controller.passwordController,
                icon: const Icon(Icons.lock, color: Colors.black87),
                validate: (value) => validateFieldCustomText(
                  value,
                  "Please enter password",
                ),
                valueChanged: (value) {},
                obscureText: !controller.isPasswordVisible.value,
                isPasswordField: true,
                isPasswordVisible: controller.isPasswordVisible.value,
                onTogglePassword: controller.togglePasswordVisibility,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton(LoginController controller) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => controller.showPasswordResetDialog(),
        child: const Text(
          "Forgot Password?",
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController controller) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: CustomButton(
        onPressed: () => controller.login(),
        myText: "Login",
        color: Colors.black,
        textColor: Colors.white,
        fontSize: 16,
        fontWeigt: FontWeight.w700,
      ),
    );
  }
}