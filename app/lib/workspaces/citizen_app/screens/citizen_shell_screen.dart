import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';
import 'citizen_home_screen.dart';
import 'citizen_laporan_screen.dart';
import 'citizen_profile_screen.dart';
import 'report_history_screen.dart';

/// Main shell untuk Citizen workspace.
/// 5 tabs: Beranda, Peta, Laporan, Riwayat, Profil.
class CitizenShellScreen extends ConsumerStatefulWidget {
  const CitizenShellScreen({super.key});

  @override
  ConsumerState<CitizenShellScreen> createState() => _CitizenShellScreenState();
}

class _CitizenShellScreenState extends ConsumerState<CitizenShellScreen> {
  final GlobalKey<RoleScaffoldState> _scaffoldKey = GlobalKey();

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) {
      await ref.read(currentUserProvider.notifier).refresh();
      if (mounted) context.go(AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final scaffold = RoleScaffold(
      key: _scaffoldKey,
      title: 'LaporIn - Warga',
      userName: user?.fullName ?? 'Warga',
      userRole: 'citizen',
      notificationRoute: AppRoutes.citizenNotifications,
      onLogout: _logout,
      tabs: [
        const RoleTab(
          label: 'Beranda',
          icon: Icons.home_outlined,
          body: CitizenHomeScreen(),
        ),
        const RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Peta'),
        ),
        const RoleTab(
          label: 'Laporan',
          icon: Icons.description_outlined,
          body: CitizenLaporanScreen(),
        ),
        const RoleTab(
          label: 'Riwayat',
          icon: Icons.history,
          body: ReportHistoryScreen(),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: CitizenProfileScreen(),
        ),
      ],
    );

    return BackPressHandler(
      isOnFirstTab: () => _scaffoldKey.currentState?.isOnFirstTab ?? true,
      onSwitchToFirstTab: () => _scaffoldKey.currentState?.switchToFirstTab(),
      child: scaffold,
    );
  }
}
