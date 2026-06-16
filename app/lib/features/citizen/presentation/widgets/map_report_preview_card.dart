import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/nearby_report.dart';

/// Kartu pratinjau laporan yang mengambang di bawah peta saat sebuah marker
/// dipilih.
///
/// Versi horizontal-ringkas dari [report_card_widget]: thumbnail kotak di kiri,
/// lalu judul + badge status, alamat, dan baris "jarak • waktu". Dipisah sebagai
/// widget reusable agar [MapScreen] tetap ringkas. Presentational murni —
/// data via [report], aksi tap via [onTap].
class MapReportPreviewCard extends StatelessWidget {
  const MapReportPreviewCard({
    super.key,
    required this.report,
    this.onTap,
  });

  final NearbyReport report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail: blok warna + ikon (pengganti foto, seperti kartu lain).
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: report.imageColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report.imageIcon,
                  size: 26,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: report.statusLabel,
                          color: report.statusColor,
                        ),
                      ],
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(report.distance, style: _metaStyle),
                        const Text('  •  ', style: _metaStyle),
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
        ),
      ),
    );
  }

  static const TextStyle _metaStyle =
      TextStyle(fontSize: 11, color: AppColors.textSecondary);
}

/// Badge status berlatar warna-transparan (mis. "Diproses" oranye).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
