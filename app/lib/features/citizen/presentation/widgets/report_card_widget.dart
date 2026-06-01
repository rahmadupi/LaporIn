import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/nearby_report.dart';

/// Kartu satu "Laporan Terdekat" untuk ditampilkan di list horizontal.
///
/// Dipisah agar logika tampilan satu kartu (gambar placeholder, badge status,
/// metadata jarak/waktu) tidak menggemukkan screen. Menerima [NearbyReport]
/// sehingga mudah diisi data dummy sekarang maupun data Firestore nanti.
class ReportCardWidget extends StatelessWidget {
  const ReportCardWidget({super.key, required this.report});

  final NearbyReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      // clipBehavior agar sudut gambar placeholder ikut membulat.
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area "gambar": blok warna + ikon sebagai pengganti foto asli,
          // dengan badge status mengambang di pojok kiri atas.
          Stack(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                color: report.imageColor,
                child: Icon(
                  report.imageIcon,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: _StatusBadge(
                  label: report.statusLabel,
                  color: report.statusColor,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Baris metadata: jarak (ikon lokasi) + waktu (ikon jam).
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(report.distance, style: _metaStyle),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        report.timeAgo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _metaStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _metaStyle =
      TextStyle(fontSize: 11, color: AppColors.textSecondary);
}

/// Badge kecil berlatar warna-transparan untuk status laporan.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titik berwarna menandai status secara cepat tanpa membaca teks.
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
