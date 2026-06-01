import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Kartu ringkasan aktivitas satu Watch Zone milik warga.
///
/// Dipisah agar bagian "Aktivitas Watch Zones Anda" di Beranda tetap ringkas.
/// Komponen ini bersifat presentational murni — data dilempar lewat parameter.
class WatchZoneCardWidget extends StatelessWidget {
  const WatchZoneCardWidget({
    super.key,
    required this.zoneName,
    required this.activityText,
  });

  final String zoneName;

  /// Teks aktivitas (mis. "2 laporan baru hari ini"), ditonjolkan oranye.
  final String activityText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ikon mata dalam lingkaran lembut — identitas visual Watch Zone.
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zoneName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activityText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
