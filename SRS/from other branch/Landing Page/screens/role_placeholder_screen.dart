import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Placeholder Home untuk role Officer & Admin.
///
/// Fitur penuh kedua role ini dikerjakan Anggota B & C di branch lain. Di
/// branch auth-setup, layar ini hanya membuktikan role-based routing: user
/// non-citizen tetap diarahkan ke tempat yang sesuai, bukan ke Citizen Home.
class RolePlaceholderScreen extends StatelessWidget {
  const RolePlaceholderScreen({super.key, required this.title});

  /// Judul yang membedakan layar (mis. "Beranda Petugas" / "Beranda Admin").
  final String title;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Login sukses sebagai: ${user?.role.value ?? '-'}'),
      ),
    );
  }
}
