import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_role.dart';
import '../auth_navigator.dart';
import '../providers/auth_provider.dart';

/// Splash Screen (S1) — entry point aplikasi.
///
/// Tugasnya: tampil singkat sambil mengecek auth state (FR-1.4), lalu
/// mengarahkan user ke Home sesuai role atau ke Login bila belum masuk.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dijalankan setelah frame pertama selesai agar context siap dipakai
    // untuk navigasi dan akses Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  /// Menentukan route berikutnya: cek session lalu redirect berbasis role.
  Future<void> _decideNextRoute() async {
    final auth = context.read<AuthProvider>();

    // Beri jeda minimal 1.5 detik (sesuai flow dokumen) agar splash tidak
    // berkedip terlalu cepat di koneksi/perangkat kencang.
    final results = await Future.wait([
      auth.checkSession(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);
    final role = results.first as UserRole?;

    if (!mounted) return; // Widget bisa saja sudah di-dispose; hindari error.

    // role null = belum login -> ke Login. Selain itu -> home sesuai role.
    final next =
        role == null ? AppRoutes.login : AuthNavigator.homeRouteFor(role);
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient biru sesuai mockup splash.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
        ),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo bulat (placeholder ikon megaphone/lapor).
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: const Icon(Icons.campaign_outlined,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'LaporIn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Laporkan. Perbaiki. Bersama.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(),
            // Indikator loading sederhana di bagian bawah.
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            const Text('Memuat...',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
