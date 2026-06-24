import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/routing/app_routes.dart';
import 'package:laporin/shared/ui/back_press_handler.dart';
import 'package:laporin/shared/ui/role_scaffold.dart';
import 'package:laporin/shared/ui/under_construction_page.dart';
import 'package:laporin/shared_domain_data/auth/providers/auth_providers.dart';

/// Main shell untuk Citizen workspace.
/// 5 tabs: Beranda, Buat Laporan, Riwayat, Peta, Notifikasi, Profil.
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
      // Navigate ke splash dulu, lalu akan redirect ke login
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
      onLogout: _logout,
      tabs: const [
        RoleTab(
          label: 'Beranda',
          icon: Icons.home_outlined,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Beranda'),
        ),
        RoleTab(
          label: 'Buat Laporan',
          icon: Icons.add_circle_outline,
          body: UnderConstructionPage(
            role: 'Citizen',
            pageName: 'Buat Laporan',
          ),
        ),
        RoleTab(
          label: 'Riwayat',
          icon: Icons.history,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Riwayat'),
        ),
        RoleTab(
          label: 'Peta',
          icon: Icons.map_outlined,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Peta'),
        ),
        RoleTab(
          label: 'Notifikasi',
          icon: Icons.notifications_outlined,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Notifikasi'),
        ),
        RoleTab(
          label: 'Profil',
          icon: Icons.person_outline,
          body: UnderConstructionPage(role: 'Citizen', pageName: 'Profil'),
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
