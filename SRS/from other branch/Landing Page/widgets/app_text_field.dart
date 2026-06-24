import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Text field reusable dengan label di atas + ikon prefix.
///
/// Dibuat sebagai satu widget agar Login & Register tidak menduplikasi
/// styling input yang sama (DRY). Menerima [controller] & [validator]
/// supaya validasi tetap dikelola oleh Form di masing-masing screen.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label ditempatkan di atas field, mengikuti desain mockup Login.
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
