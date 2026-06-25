import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';

import '../providers/admin_navigation_providers.dart';
import 'admin_dashboard_screen.dart';
import 'admin_moderation_shell_screen.dart';
import 'admin_petugas_screen.dart';
import 'admin_profile_screen.dart';

/// Main shell untuk Admin workspace.
/// 5 tabs: Dashboard (0), Peta (1), Laporan (2), Petugas (3), Profil (4).
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
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
    // Switch tab whenever the provider value changes (e.g. from dashboard
    // priority-alert drill-in).
    ref.listen<int>(adminTabIndexProvider, (previous, next) {
      _scaffoldKey.currentState?.switchToTab(next);
    });
    // Drill-in nonce: memaksa tab switch ke Laporan (2) setiap kali
    // dashboard fire drill-in, tanpa peduli apakah `adminTabIndexProvider`
    // berubah atau tidak (lihat `adminDrillInNonceProvider` untuk konteks).
    ref.listen<int>(adminDrillInNonceProvider, (previous, next) {
      _scaffoldKey.currentState?.switchToTab(2);
    });

    final user = ref.watch(currentUserProvider).valueOrNull;

    final scaffold = RoleScaffold(
      key: _scaffoldKey,
      title: 'LaporIn - Admin',
      userName: user?.fullName ?? 'Admin',
      userRole: 'admin',
      onLogout: _logout,
      tabs: [
        RoleTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          body: const AdminDashboardScreen(),
        ),
        RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: const UnderConstructionPage(role: 'Admin', pageName: 'Peta'),
        ),
        RoleTab(
          label: 'Moderasi',
          icon: Icons.description_outlined,
          body: const AdminModerationShellScreen(),
        ),
        RoleTab(
          label: 'Petugas',
          icon: Icons.engineering_outlined,
          body: const AdminPetugasScreen(),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: const AdminProfileScreen(),
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
