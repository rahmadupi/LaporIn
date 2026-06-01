import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/report.dart';
import 'status_badge.dart';

/// Kartu satu laporan di daftar Riwayat (C7).
///
/// Menampilkan thumbnail foto, kategori, alamat, badge status, dan waktu.
/// Dipisah agar layar Riwayat cukup memetakan list -> widget ini.
class ReportListCard extends StatelessWidget {
  const ReportListCard({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(url: report.primaryPhotoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris atas: kategori + badge status sejajar.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: report.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.address.isNotEmpty
                                  ? report.address
                                  : 'Alamat tidak tersedia',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.relative(report.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thumbnail foto laporan dengan fallback bila URL kosong / gagal dimuat.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: url == null
            ? const _ThumbPlaceholder()
            : Image.network(
                url!,
                fit: BoxFit.cover,
                // Tampilkan placeholder bila gambar gagal dimuat (mis. offline).
                errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _ThumbPlaceholder(isLoading: true);
                },
              ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
