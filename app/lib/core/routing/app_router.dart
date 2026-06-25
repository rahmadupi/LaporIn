import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../landing/splash/splash_screen.dart';
import '../../landing/auth/login/login_screen.dart';
import '../../landing/auth/register/register_screen.dart';
import '../../landing/auth/forgot_password/forgot_password_screen.dart';
import '../../shared_domain_data/auth/entities/user_entity.dart';
import '../../shared_domain_data/auth/entities/user_role.dart';
import '../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../workspaces/admin_app/screens/admin_shell_screen.dart';
import '../../workspaces/admin_app/screens/officer_profile_view_screen.dart';
import '../../workspaces/citizen_app/screens/citizen_shell_screen.dart';
import '../../workspaces/officer_app/screens/officer_proof_screen.dart';
import '../../workspaces/officer_app/screens/officer_shell_screen.dart';
import '../../workspaces/officer_app/screens/officer_task_detail_screen.dart';
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
        routes: [
          // Officer profile drill-in. Passes the UserEntity via `extra`
          // to avoid a re-read.
          GoRoute(
            path: 'petugas/:uid',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is UserEntity) {
                return OfficerProfileViewScreen(officer: extra);
              }
              // Fallback: fetch by uid.
              final uid = state.pathParameters['uid'] ?? '';
              return _OfficerProfileLoader(uid: uid);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.citizenHome,
        builder: (context, state) => const CitizenShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.officerHome,
        builder: (context, state) => const OfficerShellScreen(),
        routes: [
          // M2: detail satu tugas yang ditugaskan ke officer.
          // Map<String, dynamic> taskData dikirim via `extra` agar tidak
          // perlu re-read dari Firestore; fallback fetch by id.
          GoRoute(
            path: 'task/:taskId',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId'] ?? '';
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return OfficerTaskDetailScreen(taskId: taskId, taskData: extra);
              }
              return _TaskDetailLoader(taskId: taskId);
            },
          ),
          // M3: layar unggah bukti (ImgBB + Hive + GPS + voice).
          // Map<String, dynamic> taskData dikirim via `extra`.
          GoRoute(
            path: 'proof/:taskId',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId'] ?? '';
              final extra = state.extra;
              final taskData =
                  extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
              return OfficerProofScreen(taskId: taskId, taskData: taskData);
            },
          ),
        ],
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

/// Fallback loader untuk OfficerProfileViewScreen ketika navigasi
/// tidak membawa `extra: UserEntity` (mis. dari deep link / refresh).
class _OfficerProfileLoader extends ConsumerWidget {
  const _OfficerProfileLoader({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(officerByIdProvider(uid));
    return async.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Petugas')),
            body: const Center(child: Text('Officer tidak ditemukan.')),
          );
        }
        return OfficerProfileViewScreen(officer: user);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Profil Petugas')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Profil Petugas')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Fallback loader untuk OfficerTaskDetailScreen ketika navigasi
/// tidak membawa `extra: Map<String, dynamic>` (mis. dari deep link).
class _TaskDetailLoader extends ConsumerWidget {
  const _TaskDetailLoader({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('reports')
          .doc(taskId)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Tugas')),
            body: Center(
              child: Text('Tugas tidak ditemukan: ${snap.error ?? taskId}'),
            ),
          );
        }
        return OfficerTaskDetailScreen(
          taskId: taskId,
          taskData: snap.data!.data() ?? const <String, dynamic>{},
        );
      },
    );
  }
}
