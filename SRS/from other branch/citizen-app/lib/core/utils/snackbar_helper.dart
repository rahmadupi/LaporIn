import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Helper untuk menampilkan feedback singkat ke user (error/sukses).
class SnackbarHelper {
  SnackbarHelper._();

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
