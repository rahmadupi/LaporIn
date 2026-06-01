import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Citizen Home (C1) — PLACEHOLDER untuk branch feature/auth-setup.
///
/// Tujuan di branch ini hanya membuktikan bahwa role-based routing & session
/// bekerja: user dengan role `citizen` sampai ke sini setelah login. Konten
/// Beranda lengkap (hero card, riwayat, tombol Lapor) dibangun pada branch
/// fitur Reports terpisah.
class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // read: hanya butuh data sekali untuk ditampilkan, tidak perlu rebuild.
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Warga'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Tombol logout untuk menguji FR-1.4 (signOut + kembali ke Login).
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user,
                  color: AppColors.success, size: 56),
              const SizedBox(height: 16),
              Text(
                'Halo, ${user?.displayName.isNotEmpty == true ? user!.displayName : 'Warga'}!',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda masuk sebagai role: ${user?.role.value ?? '-'}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Konfirmasi sebelum logout agar tidak terjadi keluar tak sengaja.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    // Reset stack ke Login agar tombol back tidak kembali ke Home.
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}
