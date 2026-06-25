import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';

/// Card laporan reusable untuk citizen (Dashboard, Laporan, Riwayat).
///
/// Field yang dipakai sesuai [SRS/data-model.md §3.2]:
/// - `title`, `imageUrl`/`imageUrls`, `addressDetail`
/// - `urgencyLevel`, `status` (ReportStatus enum)
/// - `isAnonymous` (BR-CIT-001: tampil "Anonim" jika true)
/// - `createdAt` (tanggal relatif)
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.entity,
    required this.onTap,
    this.distanceKm,
    this.trailing,
  });

  final ReportEntity entity;
  final VoidCallback onTap;
  final double? distanceKm;
  final Widget? trailing;

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
                      entity.title.isEmpty ? '(Tanpa judul)' : entity.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (entity.addressDetail != null &&
                        entity.addressDetail!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entity.addressDetail!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _StatusPill(status: entity.status),
                        if (entity.isAnonymous) const _AnonimPill(),
                        if (distanceKm != null) _DistancePill(km: distanceKm!),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(entity.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 6),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1
          ? 'Baru saja'
          : '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
        child: const Icon(Icons.image_outlined,
            color: AppColors.textSecondary),
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

/// Pill status laporan — sama dengan StatusChip di officer_task_card
/// tapi di-copy agar citizen tidak bergantung pada officer workspace.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            status.shortLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Color _color() {
    switch (status) {
      case ReportStatus.pending:
        return const Color(0xFFF59E0B);
      case ReportStatus.inReview:
        return const Color(0xFF3B82F6);
      case ReportStatus.dispatched:
        return const Color(0xFF8B5CF6);
      case ReportStatus.inProgress:
        return const Color(0xFFEAB308);
      case ReportStatus.resolved:
        return const Color(0xFF10B981);
      case ReportStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

class _AnonimPill extends StatelessWidget {
  const _AnonimPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 10, color: AppColors.textSecondary),
          SizedBox(width: 4),
          Text(
            'Anonim',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    final text = km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_outlined,
              size: 10, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
