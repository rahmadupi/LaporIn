import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tab placeholder untuk menu yang belum dibangun di branch ini (Peta &
/// Watch Zones).
///
/// Sesuai cakupan tugas, kedua tab tersebut cukup menampilkan teks penanda.
/// Dibuat satu widget parametris agar tidak menduplikasi dua file kosong yang
/// nyaris identik.
class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fitur ini sedang dikembangkan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
