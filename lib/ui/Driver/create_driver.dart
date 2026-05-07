import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../api/repository/api_repository.dart';
import '../../customView/CustomAppBar.dart';
import '../../customView/custom_button.dart';
import '../../customView/custom_text_form_prefiex.dart';
import '../../models/driver/driver_register_model.dart';
import '../../utils/validators.dart';

class CreateDriver extends StatefulWidget {
  const CreateDriver({super.key});

  @override
  State<CreateDriver> createState() => _CreateDriverState();
}

class _CreateDriverState extends State<CreateDriver> {
  final TextEditingController emailController=TextEditingController();
  final TextEditingController phoneNumberController=TextEditingController();
  final TextEditingController passwordController=TextEditingController();
  final bool _obscureText = true;
  bool isPasswordVisible = false;

  bool isLoading=false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  height: 48,width: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffE25454)
                  ),
                  child: const Icon(Icons.close,color: Colors.white,),
                ),
              ),
              Image.asset('assets/images/driverProfile.png',height: 80,width: 80,),
              const SizedBox(height: 10,),
              const Text('Create New Driver',style: TextStyle(
                  fontSize: 28,fontFamily: 'Mulish',fontWeight: FontWeight.bold),),
              CustomTextFormPrefix(
                  myLabelText: 'User Email', 
                  keyboardType: TextInputType.emailAddress, 
                  controller: emailController, 
                  icon: const Icon(Icons.email,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter username"),
                  valueChanged: (value){}, 
                  obscureText: false
              ),
              CustomTextFormPrefix(
                  myLabelText: 'Phone Number',
                  keyboardType: TextInputType.number,
                  controller: phoneNumberController,
                  icon: const Icon(Icons.phone,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter Phone Number"),
                  valueChanged: (value){},
                  obscureText: false
              ),
              CustomTextFormPrefix(
                  myLabelText: 'Password',
                  keyboardType: TextInputType.visiblePassword,
                  controller: passwordController,
                  icon: const Icon(Icons.password,color: Colors.black,),
                  validate: (value) => validateFieldCustomText(
                      value, "Please enter Password"),
                  valueChanged: (value){},
                obscureText: !isPasswordVisible,
                isPasswordVisible: isPasswordVisible,
                isPasswordField: true,
                onTogglePassword: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              ),
              CustomButton(
                  myText: 'Submit',
                  onPressed: (){
                    driverRegistration();
                  },
                  fontSize: 20,
                  color: Colors.black,
                  textColor: Colors.white,
                  fontWeigt: FontWeight.w700)
            ],
          ),
        ),
      ),
    );
  }

  Future<void> driverRegistration() async {
    setState(() {
      isLoading = true;
    });

    var map = {
      "username": emailController.text,
      "password": passwordController.text,
      "address": {
        "type": "",
        "line1": "",
        "city": "",
        "zip": "",
        "country": "",
        "phone": phoneNumberController.text,
        "customer_name": "",
        "user_id": 0
      },
      "url": ""
    };

    print("Driver Register Map Value Is  $map");

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/Delivery.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );
      DriverRegisterModel model = await CallService().registerDriver(map);

      setState(() {
        isLoading = false;
      });
      Get.back();
      // Check if registration was successful (assuming success when message is not null)
      if (model.message != null) {
        String message = model.message ?? 'Registration successful';
        print('register msg is $message');

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver Registration Successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

      } else {
        // Handle failure case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during registration.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      print('Registration error: $e');
    }
  }

}
