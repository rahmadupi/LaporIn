import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../providers/admin_navigation_providers.dart';
import '../widgets/priority_alert_card.dart';
import '../widgets/stat_card.dart';

/// Admin Dashboard — Halaman utama admin.
///
/// Menampilkan:
/// 1. Stat Cards (2×2 grid): Laporan Masuk, Laporan Diverifikasi,
///    Pengguna Aktif, Petugas Aktif.
/// 2. Priority Alerts ("Perlu Perhatian Anda"): 4 tier (KRITIS, TINGGI,
///    SEDANG, RENDAH) dengan deskripsi generik overview.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(dashboardReportCountsProvider);
    final priorityAsync = ref.watch(priorityCountsProvider);
    final activeCitizensAsync = ref.watch(activeCitizensCountProvider);
    final activeOfficersAsync = ref.watch(activeOfficersCountProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardReportCountsProvider);
        ref.invalidate(priorityCountsProvider);
        ref.invalidate(activeCitizensCountProvider);
        ref.invalidate(activeOfficersCountProvider);
        await Future.wait([
          ref.read(dashboardReportCountsProvider.future),
          ref.read(priorityCountsProvider.future),
          ref.read(activeCitizensCountProvider.future),
          ref.read(activeOfficersCountProvider.future),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 4),
            // Text(
            //   'Selamat datang, Admin 👋',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontWeight: FontWeight.w700,
            //     color: Colors.grey.shade800,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Text(
            //   'Berikut ringkasan operasional hari ini',
            //   style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            // ),
            // const SizedBox(height: 20),

            // ===== Stat Cards (2×2) =====
            _StatCardsGrid(
              reports: reportsAsync,
              activeCitizens: activeCitizensAsync,
              activeOfficers: activeOfficersAsync,
            ),
            const SizedBox(height: 28),

            // ===== Priority Alerts =====
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Perlu Perhatian Anda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            priorityAsync.when(
              data: (counts) => _PriorityAlertsList(counts: counts),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Gagal memuat data: $e',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid({
    required this.reports,
    required this.activeCitizens,
    required this.activeOfficers,
  });
  final AsyncValue<DashboardReportCounts> reports;
  final AsyncValue<int> activeCitizens;
  final AsyncValue<int> activeOfficers;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        StatCard(
          label: 'Total Laporan Masuk',
          icon: Icons.query_stats_rounded,
          iconColor: const Color(0xFF2563EB),
          value: _resolveValue(reports, (d) => d.laporanMasuk),
        ),
        StatCard(
          label: 'Total Laporan Diverifikasi',
          icon: Icons.fact_check_rounded,
          iconColor: const Color(0xFFDC2626),
          value: _resolveValue(reports, (d) => d.laporanDiverifikasi),
        ),
        StatCard(
          label: 'Total Pengguna Aktif',
          icon: Icons.edit_note_rounded,
          iconColor: const Color(0xFF7C3AED),
          value: _resolveIntValue(activeCitizens),
        ),
        StatCard(
          label: 'Total Petugas Aktif',
          icon: Icons.verified_user_rounded,
          iconColor: const Color(0xFF2563EB),
          value: _resolveIntValue(activeOfficers),
        ),
      ],
    );
  }

  String _resolveValue(
    AsyncValue<DashboardReportCounts> async,
    int Function(DashboardReportCounts) pick,
  ) {
    return async.when(
      data: (d) => pick(d).toString(),
      loading: () => '...',
      error: (_, __) => '—',
    );
  }

  String _resolveIntValue(AsyncValue<int> async) {
    return async.when(
      data: (v) => v.toString(),
      loading: () => '...',
      error: (_, __) => '—',
    );
  }
}

class _PriorityAlertsList extends ConsumerWidget {
  const _PriorityAlertsList({required this.counts});
  final PriorityCounts counts;

  /// Switch to Moderasi → Laporan tab and pre-apply urgency + chip filter.
  ///
  /// Per the SRS dashboard spec:
  /// - KRITIS → chip "Menunggu" + urgency "critical"
  /// - TINGGI → chip "Diproses" + urgency "high"
  /// - SEDANG → chip "Diproses" + urgency "medium"
  /// - RENDAH → chip "Menunggu" + urgency "low"
  void _drillIn(
    WidgetRef ref, {
    required String urgency,
    required String chipFilter,
  }) {
    ref.read(laporanFilterProvider.notifier).state = chipFilter;
    ref.read(laporanUrgencyFilterProvider.notifier).state = urgency;
    // Bump nonce so the Laporan list rebuilds with the new filters even if
    // it was already mounted (admin stays on tab 2 across navigations).
    ref.read(laporanDrillInNonceProvider.notifier).state++;
    // Switch to the Laporan tab (index 2 in AdminShellScreen).
    ref.read(adminTabIndexProvider.notifier).state = 2;
    // Bump drill-in nonce for AdminShellScreen listener — ensures tab switch
    // fires every time, even if `adminTabIndexProvider` is already at 2 from
    // a prior drill-in (the `RoleScaffold` doesn't sync local tab state
    // back to the provider, so we need a separate trigger).
    ref.read(adminDrillInNonceProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        PriorityAlertCard(
          severity: AlertSeverity.critical,
          count: counts.kritis,
          description: 'Permasalahan sangat besar pada keselamatan publik',
          onTap: () =>
              _drillIn(ref, urgency: 'critical', chipFilter: 'Menunggu'),
        ),
        const SizedBox(height: 10),
        PriorityAlertCard(
          severity: AlertSeverity.high,
          count: counts.tinggi,
          description: 'Permasalahan besar pada lingkungan dan keselamatan',
          onTap: () => _drillIn(ref, urgency: 'high', chipFilter: 'Diproses'),
        ),
        const SizedBox(height: 10),
        PriorityAlertCard(
          severity: AlertSeverity.medium,
          count: counts.sedang,
          description: 'Permasalahan sedang pada infrastruktur',
          onTap: () => _drillIn(ref, urgency: 'medium', chipFilter: 'Diproses'),
        ),
        const SizedBox(height: 10),
        PriorityAlertCard(
          severity: AlertSeverity.low,
          count: counts.rendah,
          description: 'Permasalahan ringan',
          onTap: () => _drillIn(ref, urgency: 'low', chipFilter: 'Menunggu'),
        ),
      ],
    );
  }
}
