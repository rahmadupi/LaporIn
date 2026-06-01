import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tingkat keparahan kerusakan (Step 4).
///
/// [slug] disimpan ke Firestore (`severity`), [label] tampil di UI, [color]
/// dipakai chip pemilih agar tingkat keparahan langsung terbaca secara visual
/// (hijau = ringan, oranye = sedang, merah = berat).
enum ReportSeverity {
  low('low', 'Ringan', AppColors.success),
  medium('medium', 'Sedang', AppColors.accent),
  high('high', 'Berat', AppColors.error);

  const ReportSeverity(this.slug, this.label, this.color);

  final String slug;
  final String label;
  final Color color;

  /// Memetakan nilai Firestore (`severity`) kembali ke enum; nilai tak dikenal
  /// jatuh ke [medium] sebagai default aman.
  static ReportSeverity fromSlug(String? value) {
    return values.firstWhere(
      (s) => s.slug == value,
      orElse: () => ReportSeverity.medium,
    );
  }
}
