import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Hero Card biru ajakan melapor — komponen paling menonjol di Beranda.
///
/// Dipecah menjadi widget sendiri karena cukup kompleks (gradient, watermark
/// ikon, tombol aksi). Tombol "Buat Laporan" memanggil [onReport] yang di
/// branch ini dialihkan ke FAB "Lapor" agar satu entry-point pelaporan.
class HeroCardWidget extends StatelessWidget {
  const HeroCardWidget({super.key, required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Gradient biru memberi kedalaman sesuai mockup.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
      ),
      // Stack agar ikon peringatan bisa jadi watermark transparan di kanan.
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.warning_amber_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lihat sesuatu yang rusak?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Laporkan dalam 30 detik',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 18),
              // Tombol oranye menonjol di atas latar biru (kontras tinggi).
              ElevatedButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Buat Laporan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
