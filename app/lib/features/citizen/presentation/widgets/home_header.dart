import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Header Beranda: sapaan ke warga, lokasi saat ini, dan ikon notifikasi.
///
/// Dipisah dari screen agar bagian "identitas + lokasi" mudah dibaca dan kelak
/// gampang dihubungkan ke data user/geolokasi asli tanpa mengubah layout body.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greetingName,
    required this.location,
  });

  /// Nama yang disapa (mis. nama depan user); diisi dari AuthProvider.
  final String greetingName;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Kolom kiri: sapaan + lokasi bertumpuk vertikal.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $greetingName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Tombol notifikasi (placeholder; notification center dibangun terpisah).
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, size: 26),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}
