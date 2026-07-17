import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../customView/custom_button.dart';
import '../../customView/custom_text_form_prefiex.dart';
import '../../utils/validators.dart';
import 'loginController.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    print("📐 Orientation: ${MediaQuery.of(context).orientation}");
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
             // const SizedBox(height: 100),
              _buildLoginTitle(),
              const SizedBox(height: 30),
              _buildLoginForm(controller),
              const SizedBox(height: 10),
              _buildForgotPasswordButton(controller),
              const SizedBox(height: 20),
              _buildLoginButton(controller),
            ],
          ),
        ),
      ),
    ));
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
              Text('English (GBP)', style: TextStyle(fontSize: 16)),
              Text('English (EURO)', style: TextStyle(fontSize: 16)),
              Text('English (CHF)', style: TextStyle(fontSize: 16)),
              Text('German (CHF)', style: TextStyle(fontSize: 16)),
              Text('German (EURO)', style: TextStyle(fontSize: 16)),
            ];
          },
          items: const [
            DropdownMenuItem(
              value: 'en',
              child: Text('English (GBP)', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'ee',
              child: Text('English (EURO)', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'ec',
              child: Text('English (CHF)', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'ch',
              child: Text('German (CHF)', style: TextStyle(fontSize: 16)),
            ),
            DropdownMenuItem(
              value: 'de',
              child: Text('German (EURO)', style: TextStyle(fontSize: 16)),
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
      "Login!",
      style: TextStyle(
        fontSize: 30,
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLoginForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          CustomTextFormPrefix(
            keyboardType: TextInputType.emailAddress,
            myLabelText: "Username...",
            controller: controller.emailController,
            icon: const Icon(Icons.person, color: Colors.black),
            validate: (value) => validateFieldCustomText(
              value,
              "Please enter username",
            ),
            valueChanged: (value) {},
            obscureText: false,
          ),
          // ✅ UPDATE THIS SECTION
          Obx(() => CustomTextFormPrefix(
            keyboardType: TextInputType.visiblePassword,
            myLabelText: "Password...",
            controller: controller.passwordController,
            icon: const Icon(Icons.lock, color: Colors.black),
            validate: (value) => validateFieldCustomText(
              value,
              "Please enter password",
            ),
            valueChanged: (value) {},
            obscureText: !controller.isPasswordVisible.value,
            isPasswordField: true,
            isPasswordVisible: controller.isPasswordVisible.value,
            onTogglePassword: controller.togglePasswordVisibility,
          )),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton(LoginController controller) {
    return GestureDetector(
      onTap: () => controller.showPasswordResetDialog(),
      child: const Text(
        "Forgot Password",
        style: TextStyle(
          fontSize: 17,
          color: Colors.black,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.solid,
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController controller) {
    return CustomButton(
      onPressed: () => controller.login(),
      myText: "Login",
      color: Colors.black,
      textColor: Colors.white,
      fontSize: 17,
      fontWeigt: FontWeight.w700,
    );
  }
}