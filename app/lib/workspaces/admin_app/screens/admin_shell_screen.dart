import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';

/// Main shell untuk Admin workspace.
/// 4 tabs: Dashboard, Peta, Laporan, Petugas, Profil.
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
    final user = ref.watch(currentUserProvider).valueOrNull;

    final scaffold = RoleScaffold(
      key: _scaffoldKey,
      title: 'LaporIn - Admin',
      userName: user?.fullName ?? 'Admin',
      userRole: 'admin',
      onLogout: _logout,
      tabs: const [
        RoleTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          body: UnderConstructionPage(role: 'Admin', pageName: 'Dashboard'),
        ),
        RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: UnderConstructionPage(role: 'Admin', pageName: 'Peta'),
        ),
        RoleTab(
          label: 'Laporan',
          icon: Icons.description_outlined,
          body: UnderConstructionPage(role: 'Admin', pageName: 'Laporan'),
        ),
        RoleTab(
          label: 'Petugas',
          icon: Icons.engineering_outlined,
          body: UnderConstructionPage(role: 'Admin', pageName: 'Petugas'),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: UnderConstructionPage(role: 'Admin', pageName: 'Profil'),
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
