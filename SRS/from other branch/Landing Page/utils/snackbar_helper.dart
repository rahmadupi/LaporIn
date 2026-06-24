import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Helper untuk menampilkan feedback singkat ke user (error/sukses).
///
/// Dipusatkan agar pesan error/sukses punya gaya konsisten dan UI screen
/// tidak perlu mengulang konfigurasi SnackBar yang sama berulang kali.
class SnackbarHelper {
  SnackbarHelper._();

  /// Menampilkan pesan error (mis. login gagal) dengan warna merah.
  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  /// Menampilkan pesan sukses (mis. email reset terkirim) dengan warna hijau.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void _show(BuildContext context, String message, Color color) {
    // Hapus snackbar sebelumnya supaya pesan baru tidak menumpuk antri.
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
