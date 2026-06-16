import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:laporin/workspaces/admin_app/screens/admin_dashboard_screen.dart';
import 'package:laporin/workspaces/admin_app/screens/under_construction_screen.dart';

/// Routes for the admin workspace.
///
/// Every nav destination besides the dashboard currently points at the
/// under-construction placeholder; routes are declared explicitly so that
/// the bottom-nav highlight and deep links stay in sync.
final adminRoutes = [
  GoRoute(
    path: '/admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
  GoRoute(
    path: '/admin/under-construction',
    builder: (context, state) => const UnderConstructionScreen(),
  ),
  // Convenience aliases so deep links for the placeholder destinations
  // resolve to the same screen.
  GoRoute(
    path: '/admin/laporan',
    redirect: (_, __) => '/admin/under-construction',
  ),
  GoRoute(
    path: '/admin/petugas',
    redirect: (_, __) => '/admin/under-construction',
  ),
  GoRoute(
    path: '/admin/profil',
    redirect: (_, __) => '/admin/under-construction',
  ),
];

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/admin',
    routes: [
      // Admin Routes
      ...adminRoutes,

      // Catch-all: any unmatched path lands on the admin dashboard.
      GoRoute(
        path: '/',
        redirect: (_, __) => '/admin',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(state.error.toString())),
    ),
  );
}
