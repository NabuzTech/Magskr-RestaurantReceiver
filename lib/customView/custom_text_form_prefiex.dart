import 'package:flutter/material.dart';


class CustomTextFormPrefix extends StatelessWidget {
  final TextInputType keyboardType;
  final String myLabelText;
  final TextEditingController controller;
  final Icon icon;
  final FormFieldValidator validate;
  final ValueChanged valueChanged;
  bool obscureText;
  final bool isPasswordVisible; // Controls show/hide state
  final VoidCallback? onTogglePassword;
  final bool isPasswordField; // New parameter to identify password fields

  CustomTextFormPrefix({super.key, 
    required this.myLabelText,
    required this.keyboardType,
    required this.controller,
    required this.icon,
    required this.validate,
    required this.valueChanged,
    required this.obscureText,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.isPasswordField = false, // Default false for non-password fields
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        textAlign: TextAlign.start,
        cursorColor: Colors.blue,
        controller: controller,
        validator: validate,
        onChanged: valueChanged,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: icon,
          prefixIconColor: WidgetStateColor.resolveWith((states) =>
          states.contains(WidgetState.focused)
              ? Colors.green
              : Colors.green),
          hintText: myLabelText,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          border: InputBorder.none,
          suffixIcon: isPasswordField // Show toggle icon for password fields only
              ? IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            onPressed: onTogglePassword,
          )
              : null,
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontFamily: 'Montserrat',
          ),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}