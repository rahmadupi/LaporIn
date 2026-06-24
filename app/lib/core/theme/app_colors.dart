import 'package:flutter/material.dart';

/// Palet warna terpusat untuk seluruh aplikasi.
///
/// Disimpan di satu tempat (single source of truth) agar konsisten di semua
/// screen dan mudah diganti — sesuai design system yang disepakati tim.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF21509E);
  static const Color primaryDark = Color(0xFF163C7A);
  static const Color primaryLight = Color(0xFF3D6FBF);

  static const Color scaffoldBackground = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE2E5EC);

  static const Color error = Color(0xFFD92D20);
  static const Color success = Color(0xFF12B76A);

  static const Color accent = Color(0xFFF59E0B);

  static const Color primarySoft = Color(0xFFE8EFFB);
}
