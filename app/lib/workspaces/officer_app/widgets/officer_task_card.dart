import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';

/// Kartu tugas yang ditampilkan di Officer Home (M1) dan Officer
/// History (M4). Tap memanggil [onTap] dengan entity, sehingga parent
/// bisa push ke Task Detail atau menampilkan read-only view.
///
/// Props:
/// - [entity]: ReportEntity (wajib).
/// - [onTap]: callback ketika kartu ditekan.
class OfficerTaskCard extends StatelessWidget {
  const OfficerTaskCard({super.key, required this.entity, required this.onTap});

  final ReportEntity entity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = entity.imageUrl ??
        (entity.imageUrls.isNotEmpty ? entity.imageUrls.first : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.title.isEmpty ? 'Tanpa Judul' : entity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entity.addressDetail ??
                                _formatLatLng(entity.latitude, entity.longitude),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip(status: entity.status),
                        const SizedBox(width: 6),
                        UrgencyChip(urgency: entity.urgencyLevel),
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

  String _formatLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Lokasi tidak diketahui';
    return 'Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}';
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.scaffoldBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          color: AppColors.scaffoldBackground,
          child: const Icon(Icons.broken_image,
              size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Chip kecil berwarna untuk status laporan. Dipakai di kartu tugas
/// dan badge header Task Detail.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    switch (status) {
      case ReportStatus.resolved:
        return AppColors.success;
      case ReportStatus.inProgress:
        return AppColors.primary;
      case ReportStatus.dispatched:
        return AppColors.accent;
      case ReportStatus.inReview:
        return AppColors.accent;
      case ReportStatus.rejected:
        return AppColors.error;
      case ReportStatus.pending:
        return AppColors.textSecondary;
    }
  }
}

/// Chip kecil untuk tingkat urgensi. Dipakai di kartu tugas.
class UrgencyChip extends StatelessWidget {
  const UrgencyChip({super.key, required this.urgency});

  final ReportUrgency urgency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 10, color: _color()),
          const SizedBox(width: 4),
          Text(
            urgency.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _color(),
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    switch (urgency) {
      case ReportUrgency.critical:
        return AppColors.error;
      case ReportUrgency.high:
        return AppColors.accent;
      case ReportUrgency.medium:
        return AppColors.primary;
      case ReportUrgency.low:
        return AppColors.success;
    }
  }
}
