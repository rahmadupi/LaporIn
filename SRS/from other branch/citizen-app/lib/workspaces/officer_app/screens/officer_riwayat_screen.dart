import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';

/// Officer Riwayat (M4) — daftar laporan yang sudah **selesai**
/// (`status: resolved`) dan di-assign ke officer yang sedang login.
///
/// Tap kartu → push ke `OfficerTaskDetailScreen` dalam mode read-only
/// (action bar disembunyikan, tapi proof section tetap tampil).
class OfficerRiwayatScreen extends ConsumerWidget {
  const OfficerRiwayatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sesi login tidak ditemukan.'),
        ),
      );
    }
    final async = ref.watch(myOfficerHistoryProvider(user.uid));

    return async.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada tugas yang selesai.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myOfficerHistoryProvider(user.uid));
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _RiwayatCard(report: reports[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat riwayat: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(myOfficerHistoryProvider(user.uid)),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  const _RiwayatCard({required this.report});

  final ReportEntity report;

  void _openDetail(BuildContext context) {
    final data = <String, dynamic>{
      'title': report.title,
      'description': report.description,
      'imageUrl':
          report.imageUrl ??
          (report.imageUrls.isNotEmpty ? report.imageUrls.first : null),
      'imageUrls': report.imageUrls,
      'addressDetail': report.addressDetail,
      'urgencyLevel': report.urgencyLevel.value,
      'status': report.status.value,
      'rejectComment': report.rejectComment,
      'proofUrl': report.proofUrl,
      'photoBeforeUrl': null,
      'photoAfterUrl': null,
      'proofDescription': null,
      'assignedOfficerId': report.assignedOfficerId,
      'createdAt': report.createdAt,
      'updatedAt': report.updatedAt,
    };
    context.push(AppRoutes.officerTaskDetailFor(report.reportId), extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = report.heroImageUrl;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl.isEmpty
                      ? Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title.isEmpty ? '(Tanpa judul)' : report.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (report.formattedAddress.isNotEmpty)
                      Text(
                        report.formattedAddress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'LPR-${_shortTicket(report.reportId)} • '
                      '${_formatDate(report.updatedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (report.proofUrl != null &&
                        report.proofUrl!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bukti terunggah',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
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

  String _shortTicket(String id) => id.length <= 10 ? id : id.substring(0, 10);

  String _formatDate(DateTime d) {
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
    final dd = d.day.toString().padLeft(2, '0');
    final mm = months[d.month - 1];
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$dd $mm $yy';
  }
}
