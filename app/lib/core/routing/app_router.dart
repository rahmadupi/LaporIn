import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../landing/splash/splash_screen.dart';
import '../../landing/auth/login/login_screen.dart';
import '../../landing/auth/register/register_screen.dart';
import '../../landing/auth/forgot_password/forgot_password_screen.dart';
import '../../shared_domain_data/auth/entities/user_role.dart';
import '../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../workspaces/admin_app/screens/admin_shell_screen.dart';
import '../../workspaces/citizen_app/screens/citizen_shell_screen.dart';
import '../../workspaces/officer_app/screens/officer_shell_screen.dart';
import 'app_routes.dart';

/// GoRouter dengan auth guard (Riverpod).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      final isLoggedIn = currentUser != null;
      final matched = state.matchedLocation;

      // Izinkan splash, login, register, forgot-password diakses tanpa auth
      final isAuthRoute =
          matched == AppRoutes.login ||
          matched == AppRoutes.register ||
          matched == AppRoutes.forgotPassword ||
          matched == AppRoutes.splash;

      // Belum login & bukan halaman auth -> redirect ke login
      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Sudah login & masih di halaman auth -> redirect ke workspace
      if (isLoggedIn && isAuthRoute && matched != AppRoutes.splash) {
        return _routeForRole(currentUser.role);
      }

      // Sudah login tapi role tidak sesuai dengan workspace yang dituju
      if (isLoggedIn && !isAuthRoute) {
        final expectedRoute = _routeForRole(currentUser.role);
        if (matched != expectedRoute && matched != AppRoutes.splash) {
          return expectedRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.citizenHome,
        builder: (context, state) => const CitizenShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.officerHome,
        builder: (context, state) => const OfficerShellScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
});

String _routeForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.officer:
      return AppRoutes.officerHome;
    case UserRole.citizen:
    case UserRole.unknown:
      return AppRoutes.citizenHome;
  }
}
