import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';

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
      onLogout: _logout,
      tabs: const [
        RoleTab(
          label: 'TAB 1',
          icon: Icons.dashboard_outlined,
          body: UnderConstructionPage(role: 'Officer', pageName: 'TAB 1'),
        ),
        RoleTab(
          label: 'TAB 2',
          icon: Icons.list_alt_outlined,
          body: UnderConstructionPage(role: 'Officer', pageName: 'TAB 2'),
        ),
        RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: UnderConstructionPage(role: 'Officer', pageName: 'Peta'),
        ),
        RoleTab(
          label: 'TAB 4',
          icon: Icons.history,
          body: UnderConstructionPage(role: 'Officer', pageName: 'TAB 4'),
        ),
        RoleTab(
          label: 'Notifikasi',
          icon: Icons.notifications_outlined,
          body: UnderConstructionPage(role: 'Officer', pageName: 'Notifikasi'),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: UnderConstructionPage(role: 'Officer', pageName: 'Profil'),
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
