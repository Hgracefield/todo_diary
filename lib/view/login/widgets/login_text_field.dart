import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.height = 74,
    this.fontSize = 24,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.focusNode,
    this.textColor,
    this.suffixIcon,
    this.obscuringCharacter = '*',
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final double height;
  final double fontSize;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Color? textColor;
  final Widget? suffixIcon;
  final String obscuringCharacter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        obscuringCharacter: obscuringCharacter,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: TextStyle(
          color: enabled
              ? textColor ?? const Color(0xFF333333)
              : const Color(0xFFB8B8B8),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF2F2F2),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color(0xFFDADADA),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF78BFAE), width: 1.4),
          ),
        ),
      ),
    );
  }
}
