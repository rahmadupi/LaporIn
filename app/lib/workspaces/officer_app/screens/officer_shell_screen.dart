import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';
import 'officer_home_screen.dart';
import 'officer_laporan_screen.dart';
import 'officer_profile_screen.dart';
import 'officer_riwayat_screen.dart';

/// Main shell untuk Officer workspace.
/// 5 tabs: TAB 1 - TAB 5.
class OfficerShellScreen extends ConsumerStatefulWidget {
  const OfficerShellScreen({super.key});

  @override
  ConsumerState<OfficerShellScreen> createState() => _OfficerShellScreenState();
}

class _OfficerShellScreenState extends ConsumerState<OfficerShellScreen> {
  final GlobalKey<RoleScaffoldState> _scaffoldKey = GlobalKey();

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) {
      await ref.read(currentUserProvider.notifier).refresh();
      // Navigate ke splash dulu, lalu akan redirect ke login
      if (mounted) context.go(AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    final scaffold = RoleScaffold(
      key: _scaffoldKey,
      title: 'LaporIn - Petugas',
      userName: user?.fullName ?? 'Petugas',
      userRole: 'officer',
      notificationRoute: AppRoutes.officerNotifications,
      onLogout: _logout,
      tabs: [
        // M1: Home tab — daftar tugas aktif + filter chips + FAB darurat.
        const RoleTab(
          label: 'Tugas',
          icon: Icons.dashboard_outlined,
          body: OfficerHomeScreen(),
        ),
        const RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: UnderConstructionPage(role: 'Officer', pageName: 'Peta'),
        ),
        // M5: Laporan — feed publik untuk self-request.
        const RoleTab(
          label: 'Laporan',
          icon: Icons.description_outlined,
          body: OfficerLaporanScreen(),
        ),
        // M4: Riwayat — tugas yang sudah selesai.
        const RoleTab(
          label: 'Riwayat',
          icon: Icons.history,
          body: OfficerRiwayatScreen(),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: OfficerProfileScreen(),
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
