import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared_domain_data/auth/entities/user_entity.dart';
import '../../shared_domain_data/auth/entities/user_role.dart';
import '../../shared_domain_data/auth/providers/auth_providers.dart';

/// Splash Screen — reactive navigation based on auth state.
///
/// Tunggu currentUserProvider siap, lalu navigate:
/// - User logged in → workspace sesuai role
/// - User not logged in → login page
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  /// Cek auth state. Jika masih loading, ref.listen akan trigger lagi nanti.
  void _checkAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser.hasValue) {
      _navigateTo(currentUser.value);
    } else if (currentUser.hasError) {
      _navigateTo(null);
    }
  }

  void _navigateTo(UserEntity? user) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // Beri jeda singkat agar splash screen terlihat oleh pengguna
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (user != null) {
        context.go(_getRouteForRole(user.role));
      } else {
        context.go(AppRoutes.login);
      }
    });
  }

  String _getRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.officer:
        return '/officer';
      case UserRole.citizen:
      case UserRole.unknown:
        return '/citizen';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen untuk perubahan auth state - navigate ketika data ready
    ref.listen<AsyncValue<UserEntity?>>(currentUserProvider, (previous, next) {
      if (_hasNavigated) return;
      if (next.hasValue) {
        _navigateTo(next.value);
      } else if (next.hasError) {
        _navigateTo(null);
      }
    });

    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, color: Colors.white, size: 96),
            SizedBox(height: 24),
            Text(
              'LaporIn',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Laporkan - Perbaiki - Bersama',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
