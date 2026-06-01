import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Konfigurasi ThemeData global aplikasi.
///
/// Dipusatkan di sini supaya seluruh screen mewarisi gaya yang sama
/// (font, warna, bentuk input) tanpa mengulang styling di tiap widget.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      // Skema warna diturunkan dari satu seed agar komponen Material konsisten.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
    );

    return base.copyWith(
      // Gaya default tombol utama "Masuk"/"Daftar" agar seragam di semua screen.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52), // Touch target >44px (NFR-5).
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      // Styling input field dipusatkan agar Login & Register tampak identik.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, width: 1.5),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  /// Helper kecil untuk membuat border input dengan radius konsisten.
  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
