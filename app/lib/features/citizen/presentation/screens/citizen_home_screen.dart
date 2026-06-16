import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../../reports/presentation/providers/report_history_notifier.dart';
import '../../../reports/presentation/screens/report_detail_screen.dart';
import '../../domain/repositories/watch_zone_repository.dart';
import '../providers/nearby_reports_notifier.dart';
import '../providers/watch_zone_notifier.dart';
import '../widgets/hero_card_widget.dart';
import '../widgets/home_header.dart';
import '../widgets/report_card_widget.dart';
import '../widgets/stat_item_card.dart';
import '../widgets/watch_zone_card_widget.dart';

/// Citizen Home / Beranda (C1) — semua data REAL dari Firestore.
///
/// Menyediakan tiga stream berumur-layar:
///   * [ReportHistoryNotifier] — statistik laporan milik user.
///   * [NearbyReportsNotifier] — daftar "Laporan Terdekat" (publik).
///   * [WatchZoneNotifier] — ringkasan Watch Zone milik user.
/// Tombol "Lapor" diberikan parent (Main Navigation) lewat [onReportTap].
class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key, required this.onReportTap});

  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    final firstName = (auth.user?.displayName.trim().isNotEmpty ?? false)
        ? auth.user!.displayName.trim().split(' ').first
        : 'Warga';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => ReportHistoryNotifier(
            repository: ctx.read<ReportsRepository>(),
            reporterId: uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NearbyReportsNotifier(repository: ctx.read<ReportsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => WatchZoneNotifier(
            repository: ctx.read<WatchZoneRepository>(),
            userId: uid,
          ),
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              HomeHeader(
                greetingName: firstName,
                location: 'Sidoarjo, Jawa Timur',
                onHistoryTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.citizenReports),
                onNotificationTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.citizenNotifications),
              ),
              const SizedBox(height: 16),
              HeroCardWidget(onReport: onReportTap),
              const SizedBox(height: 20),
              const _StatsRow(),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Laporan Terdekat',
                actionLabel: 'Lihat Peta →',
              ),
              const SizedBox(height: 12),
              const _NearbyList(),
              const SizedBox(height: 24),
              const Text(
                'Aktivitas Watch Zones Anda',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const _WatchZoneSummary(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris tiga statistik NYATA: laporan aktif, selesai, jumlah watch zone.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportHistoryNotifier>();
    final zones = context.watch<WatchZoneNotifier>();

    final active = reports.countFor(ReportFilter.waiting) +
        reports.countFor(ReportFilter.inProgress);
    final done = reports.countFor(ReportFilter.done);

    return Row(
      children: [
        Expanded(
          child: StatItemCard(
            value: '$active',
            label: 'Laporan Aktif',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatItemCard(
            value: '$done',
            label: 'Selesai',
            valueColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatItemCard(
            value: '${zones.count}',
            label: 'Watch Zones',
            valueColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// List horizontal "Laporan Terdekat" dari data publik nyata.
class _NearbyList extends StatelessWidget {
  const _NearbyList();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NearbyReportsNotifier>();

    if (notifier.status == NearbyStatus.loading) {
      return const SizedBox(
        height: 210,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (notifier.isEmpty) {
      return _hint('Belum ada laporan di sekitar. Jadilah yang pertama melapor!');
    }

    // Tampilkan maksimal 10 laporan terdekat di Beranda.
    final items = notifier.items.take(10).toList();
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final report = items[index];
          return ReportCardWidget(
            report: report,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(reportId: report.reportId),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _hint(String text) {
    return Container(
      height: 110,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Ringkasan Watch Zone pertama milik user (atau ajakan membuat zona).
class _WatchZoneSummary extends StatelessWidget {
  const _WatchZoneSummary();

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<WatchZoneNotifier>();

    if (zones.status == WatchZoneStatus.loading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (zones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Belum ada Watch Zone. Tambahkan area untuk memantau laporan di '
          'sekitarnya.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    final zone = zones.zones.first;
    return WatchZoneCardWidget(
      zoneName: zone.name,
      activityText: zone.address.isNotEmpty ? zone.address : 'Area dipantau',
      hasActivity: false,
    );
  }
}
