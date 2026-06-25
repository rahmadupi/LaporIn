import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/dispatches/data/repositories/dispatch_repository.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/self_request_button.dart';

/// Officer Laporan (M5) — feed publik berisi laporan yang tersedia
/// untuk di-request oleh Petugas Lapangan (`pending` + `in_review`).
///
/// Layout mengikuti `AdminLaporanListScreen` (filter chips + urgency
/// dropdown + list kaya), tetapi **tanpa** action Terima/Tolak karena
/// officer tidak melakukan moderasi. Sebagai gantinya, tiap kartu
/// menampilkan status self-request via [SelfRequestButton] (CTA "Saya
/// Ingin Menangani" atau badge "Sudah Diajukan").
class OfficerLaporanScreen extends ConsumerStatefulWidget {
  const OfficerLaporanScreen({super.key});

  @override
  ConsumerState<OfficerLaporanScreen> createState() =>
      _OfficerLaporanScreenState();
}

enum _Filter { semua, tersedia, mendesak }

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.semua:
        return 'Semua';
      case _Filter.tersedia:
        return 'Tersedia';
      case _Filter.mendesak:
        return 'Mendesak';
    }
  }
}

class _OfficerLaporanScreenState extends ConsumerState<OfficerLaporanScreen> {
  _Filter _filter = _Filter.semua;
  ReportUrgency? _urgencyFilter;

  List<ReportEntity> _applyFilter(List<ReportEntity> all) {
    Iterable<ReportEntity> result = all;
    // Hanya tampilkan laporan yang masih tersedia untuk di-handle.
    // Status `dispatched`/`in_progress`/`resolved`/`rejected` tidak
    // muncul di sini — itu domain Riwayat.
    result = result.where(
      (r) =>
          r.status == ReportStatus.pending || r.status == ReportStatus.inReview,
    );

    switch (_filter) {
      case _Filter.semua:
        break;
      case _Filter.tersedia:
        result = result.where(
          (r) => r.assignedOfficerId == null || r.assignedOfficerId!.isEmpty,
        );
        break;
      case _Filter.mendesak:
        result = result.where(
          (r) =>
              r.urgencyLevel == ReportUrgency.high ||
              r.urgencyLevel == ReportUrgency.critical,
        );
        break;
    }

    if (_urgencyFilter != null) {
      result = result.where((r) => r.urgencyLevel == _urgencyFilter);
    }
    return result.toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(allReportsStreamProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    // Trigger the provider so the SelfRequestButton state is reactive.
    if (user != null) {
      ref.watch(mySelfRequestedReportIdsProvider(user.uid));
    }

    return Column(
      children: [
        _FilterBar(
          current: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Row(
            children: [
              Text(
                'Urgensi:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              DropdownButton<ReportUrgency?>(
                value: _urgencyFilter,
                hint: const Text('Semua'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua')),
                  for (final u in ReportUrgency.values)
                    DropdownMenuItem(value: u, child: Text(u.label)),
                ],
                onChanged: (v) => setState(() => _urgencyFilter = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              final filtered = _applyFilter(reports);
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada laporan pada filter ini.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allReportsStreamProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ReportRow(report: filtered[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});

  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: _Filter.values.map((f) {
            final isActive = f == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isActive,
                onSelected: (_) => onChanged(f),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.scaffoldBackground,
                side: BorderSide(
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Satu baris laporan — layout mengikuti admin (thumbnail 64x64, title,
/// pill status + urgency, ticket id + tanggal, alamat).
class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.report});

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
      'assignedOfficerId': report.assignedOfficerId,
      'createdAt': report.createdAt,
    };
    context.push(AppRoutes.officerTaskDetailFor(report.reportId), extra: data);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Pill(
                              label: report.status.shortLabel,
                              color: _statusColor(report.status),
                            ),
                            _Pill(
                              label: report.severity.label,
                              color: _urgencyColor(report.severity),
                              outlined: true,
                            ),
                            if (report.isAnonymous)
                              const _Pill(
                                label: 'Anonim',
                                color: Color(0xFF6B7280),
                                outlined: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LPR-${_shortTicket(report.reportId)} • '
                          '${_formatDate(report.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (report.formattedAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            report.formattedAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelfRequestButton(reportId: report.reportId),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
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

  Color _urgencyColor(ReportSeverity u) {
    switch (u) {
      case ReportSeverity.critical:
        return const Color(0xFFDC2626);
      case ReportSeverity.high:
        return const Color(0xFFEA580C);
      case ReportSeverity.medium:
        return const Color(0xFFCA8A04);
      case ReportSeverity.low:
        return const Color(0xFF16A34A);
    }
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
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd $mm, $hh:$mn';
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        border: Border.all(
          color: outlined ? color : color.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
