import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../../reports/presentation/providers/report_history_notifier.dart';
import '../../domain/repositories/watch_zone_repository.dart';
import '../providers/watch_zone_notifier.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/stat_item_card.dart';

/// Citizen Profile / Profil Saya (C9).
///
/// Header + statistik NYATA (jumlah laporan & watch zone milik user) + menu.
/// Logout memanggil AuthProvider.signOut() (FR-1.4).
class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid ?? '';
    final name = (auth.user?.displayName.trim().isNotEmpty ?? false)
        ? auth.user!.displayName.trim()
        : 'Warga';
    final email = auth.user?.email.trim() ?? '';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => ReportHistoryNotifier(
            repository: ctx.read<ReportsRepository>(),
            reporterId: uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => WatchZoneNotifier(
            repository: ctx.read<WatchZoneRepository>(),
            userId: uid,
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil Saya',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ProfileHeaderWidget(name: name, email: email),
            const SizedBox(height: 20),
            const _StatsRow(),
            const SizedBox(height: 24),
            ProfileMenuTile(
              icon: Icons.notifications_none,
              title: 'Notifikasi',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.citizenNotifications),
            ),
            ProfileMenuTile(
              icon: Icons.history,
              title: 'Riwayat Laporan',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.citizenReports),
            ),
            ProfileMenuTile(
              icon: Icons.info_outline,
              title: 'Tentang LaporIn',
              onTap: () => _showAbout(context),
            ),
            const SizedBox(height: 4),
            ProfileMenuTile(
              icon: Icons.logout,
              title: 'Keluar',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'LaporIn',
      applicationVersion: '0.1.0',
      children: const [
        Text(
          'LaporIn membantu warga melaporkan kerusakan infrastruktur publik '
          '(mendukung SDG 11) dengan jejak audit yang transparan (SDG 16).',
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}

/// Baris statistik profil NYATA: total laporan, selesai, watch zones.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportHistoryNotifier>();
    final zones = context.watch<WatchZoneNotifier>();

    final total = reports.countFor(ReportFilter.all);
    final done = reports.countFor(ReportFilter.done);

    return Row(
      children: [
        Expanded(
          child: StatItemCard(
            value: '$total',
            label: 'Total Laporan',
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
