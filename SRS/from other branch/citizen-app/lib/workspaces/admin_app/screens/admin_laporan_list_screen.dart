import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../providers/admin_navigation_providers.dart';
import '../widgets/dialogs/reject_report_dialog.dart';
import '../widgets/dispatch_form_sheet.dart';

/// Filter chips untuk Moderasi → Laporan.
enum LaporanFilter {
  semua('Semua'),
  menunggu('Menunggu'),
  diproses('Diproses'),
  selesai('Selesai'),
  ditolak('Ditolak');

  const LaporanFilter(this.label);
  final String label;

  bool matches(ReportStatus status) {
    switch (this) {
      case LaporanFilter.semua:
        return true;
      case LaporanFilter.menunggu:
        return status == ReportStatus.pending;
      case LaporanFilter.diproses:
        return status == ReportStatus.inReview ||
            status == ReportStatus.dispatched ||
            status == ReportStatus.inProgress;
      case LaporanFilter.selesai:
        return status == ReportStatus.resolved;
      case LaporanFilter.ditolak:
        return status == ReportStatus.rejected;
    }
  }
}

/// Moderation → Laporan sub-page.
///
/// Detailed list dengan inline Terima/Tolak pada baris pending.
class AdminLaporanListScreen extends ConsumerStatefulWidget {
  const AdminLaporanListScreen({
    super.key,
    this.initialFilter,
    this.initialUrgency,
  });

  /// Optional initial filter chip (e.g. from dashboard drill-in).
  final LaporanFilter? initialFilter;

  /// Optional initial urgency filter (from dashboard drill-in).
  final ReportUrgency? initialUrgency;

  @override
  ConsumerState<AdminLaporanListScreen> createState() =>
      _AdminLaporanListScreenState();
}

class _AdminLaporanListScreenState
    extends ConsumerState<AdminLaporanListScreen> {
  late LaporanFilter _filter;
  ReportUrgency? _urgencyFilter;
  int _lastNonce = -1;

  @override
  void initState() {
    super.initState();
    // Pull initial values from the providers (set by AdminShellScreen when
    // the dashboard drill-in fires). Widget params take precedence.
    final provFilterLabel = ref.read(laporanFilterProvider);
    _filter = _parseFilterLabel(widget.initialFilter?.label ?? provFilterLabel);
    final provUrgency = ref.read(laporanUrgencyFilterProvider);
    _urgencyFilter =
        widget.initialUrgency ??
        (provUrgency != null ? ReportUrgency.fromString(provUrgency) : null);
    _lastNonce = ref.read(laporanDrillInNonceProvider);
  }

  /// Map chip label string ke enum.
  LaporanFilter _parseFilterLabel(String label) {
    return LaporanFilter.values.firstWhere(
      (f) => f.label == label,
      orElse: () => LaporanFilter.semua,
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to dashboard drill-in by re-applying the providers.
    final nonce = ref.watch(laporanDrillInNonceProvider);
    if (nonce != _lastNonce) {
      _lastNonce = nonce;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final label = ref.read(laporanFilterProvider);
        final urg = ref.read(laporanUrgencyFilterProvider);
        setState(() {
          _filter = _parseFilterLabel(label);
          _urgencyFilter = urg != null ? ReportUrgency.fromString(urg) : null;
        });
      });
    }

    final reportsAsync = ref.watch(allReportsStreamProvider);
    // Read the location filter providers here so the build re-runs whenever
    // any of them change (the dropdowns update these on selection).
    final provinceFilter = ref.watch(laporanProvinceFilterProvider);
    final cityFilter = ref.watch(laporanCityFilterProvider);
    final districtFilter = ref.watch(laporanDistrictFilterProvider);

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              for (final f in LaporanFilter.values) ...[
                ChoiceChip(
                  label: Text(f.label),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),

        // Urgency dropdown + count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                'Urgensi:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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

        // ===== Location filter (Province → City → District) =====
        _LocationFilterBar(reports: reportsAsync.valueOrNull ?? []),

        const SizedBox(height: 4),

        // List
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              final filtered = reports.where((r) {
                if (!_filter.matches(r.status)) return false;
                if (_urgencyFilter != null &&
                    r.urgencyLevel != _urgencyFilter) {
                  return false;
                }
                if (provinceFilter != null &&
                    (r.province == null || r.province != provinceFilter)) {
                  return false;
                }
                if (cityFilter != null &&
                    (r.city == null || r.city != cityFilter)) {
                  return false;
                }
                if (districtFilter != null &&
                    (r.district == null || r.district != districtFilter)) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ReportRow(report: filtered[i]),
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

/// Satu baris laporan dengan layout besar (140dp+).
class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.report});
  final ReportEntity report;

  Future<void> _terima(BuildContext context, WidgetRef ref) async {
    try {
      // Tahap 1: terima laporan → status `in_review`.
      await ref
          .read(reportRepositoryProvider)
          .acceptToInReview(report.reportId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan diterima.')));

      // Tahap 2: buka Dispatch Form (officer picker) — admin wajib
      // memilih officer untuk menugaskan laporan. Submit form ini akan
      // menjalankan **batched write** atomik:
      //   - Buat `/dispatches/{id}` baru
      //   - Update `/reports/{id}` → `dispatched` + `assignedOfficerId` +
      //     `dispatchedAt`
      //   - (Jika ada ajuan diri) update sub-doc officer `applied` → `accepted`
      await DispatchFormSheet.showForAdminInitiated(context, report: report);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menerima laporan: $e')));
      }
    }
  }

  Future<void> _tolak(BuildContext context, WidgetRef ref) async {
    final result = await RejectReportDialog.show(context);
    if (result == null) return;
    try {
      await ref
          .read(reportRepositoryProvider)
          .reject(
            reportId: report.reportId,
            rejectComment: result.rejectComment,
            duplicateOfId: result.duplicateOfId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Laporan ditolak.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menolak laporan: $e')));
      }
    }
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

  Color _urgencyColor(ReportUrgency u) {
    switch (u) {
      case ReportUrgency.critical:
        return const Color(0xFFDC2626);
      case ReportUrgency.high:
        return const Color(0xFFEA580C);
      case ReportUrgency.medium:
        return const Color(0xFFCA8A04);
      case ReportUrgency.low:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = report.heroImageUrl;
    final canModerate = report.status == ReportStatus.pending;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canModerate
            ? null
            : () {
                // TODO: navigate to Detail page
              },
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
                  // Thumbnail
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
                              label: report.urgencyLevel.label,
                              color: _urgencyColor(report.urgencyLevel),
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
                          'LPR-${report.reportId.substring(0, report.reportId.length.clamp(0, 10))} • '
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
              if (canModerate) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _tolak(context, ref),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _terima(context, ref),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Terima'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(5),
        border: outlined ? Border.all(color: color, width: 1) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: outlined ? color : Colors.white,
        ),
      ),
    );
  }
}

/// Baris filter lokasi 3-level: Provinsi → Kota → Kecamatan/Desa.
///
/// Dropdown options di-populate dari daftar laporan yang tersedia.
/// Setiap perubahan dropdown menulis ke provider yang sesuai dan
/// me-reset child dropdown (mis. ganti provinsi → reset kota & desa).
class _LocationFilterBar extends ConsumerWidget {
  const _LocationFilterBar({required this.reports});
  final List<ReportEntity> reports;

  /// Kumpulkan nilai unik untuk satu field, exclude null, sort alfabetis.
  List<String> _uniqueValues(String Function(ReportEntity) pick) {
    final set = <String>{};
    for (final r in reports) {
      final v = pick(r);
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = ref.watch(laporanProvinceFilterProvider);
    final city = ref.watch(laporanCityFilterProvider);
    final district = ref.watch(laporanDistrictFilterProvider);

    // Provinces — selalu semua provinsi yang ada di laporan.
    final provinces = _uniqueValues((r) => r.province ?? '');

    // Cities — difilter berdasarkan province yang dipilih (jika ada).
    final cities = _uniqueValues(
      (r) => (province == null || r.province == province) ? (r.city ?? '') : '',
    );

    // Districts — difilter berdasarkan province + city yang dipilih.
    final districts = _uniqueValues(
      (r) =>
          (province == null || r.province == province) &&
              (city == null || r.city == city)
          ? (r.district ?? '')
          : '',
    );

    final hasAnyFilter = province != null || city != null || district != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Lokasi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              if (hasAnyFilter)
                TextButton(
                  onPressed: () {
                    ref.read(laporanProvinceFilterProvider.notifier).state =
                        null;
                    ref.read(laporanCityFilterProvider.notifier).state = null;
                    ref.read(laporanDistrictFilterProvider.notifier).state =
                        null;
                    ref
                        .read(laporanLocationResetNonceProvider.notifier)
                        .state++;
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 28),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _LocationDropdown<String?>(
                  hint: 'Provinsi',
                  value: province,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Provinsi'),
                    ),
                    for (final p in provinces)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) {
                    ref.read(laporanProvinceFilterProvider.notifier).state = v;
                    // Reset child dropdowns.
                    ref.read(laporanCityFilterProvider.notifier).state = null;
                    ref.read(laporanDistrictFilterProvider.notifier).state =
                        null;
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _LocationDropdown<String?>(
                  hint: 'Kota',
                  value: city,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Kota'),
                    ),
                    for (final c in cities)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    ref.read(laporanCityFilterProvider.notifier).state = v;
                    ref.read(laporanDistrictFilterProvider.notifier).state =
                        null;
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _LocationDropdown<String?>(
                  hint: 'Desa',
                  value: district,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Desa'),
                    ),
                    for (final d in districts)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) {
                    ref.read(laporanDistrictFilterProvider.notifier).state = v;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact dropdown used in [_LocationFilterBar].
class _LocationDropdown<T> extends StatelessWidget {
  const _LocationDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
