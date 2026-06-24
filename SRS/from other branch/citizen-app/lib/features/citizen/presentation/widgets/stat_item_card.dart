import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Kartu statistik tunggal: satu angka besar berwarna + label di bawahnya.
///
/// Dipisah menjadi widget sendiri karena dipakai DUA tempat dengan bentuk yang
/// sama persis — baris statistik di Beranda (12/47/3) dan di Profil (24/92%/3).
/// Satu widget reusable mencegah duplikasi styling kartu.
class StatItemCard extends StatelessWidget {
  const StatItemCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    // Expanded dipakai oleh pemanggil di dalam Row agar tiga kartu sama lebar.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
