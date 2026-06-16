import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:laporin/workspaces/admin_app/screens/admin_dashboard_screen.dart';
import 'package:laporin/workspaces/admin_app/screens/under_construction_screen.dart';

final adminRoutes = [
  GoRoute(
    path: '/admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
  GoRoute(
    path: '/admin/under-construction',
    builder: (context, state) => const UnderConstructionScreen(),
  ),
];

GoRouter createRouter() {
  return GoRouter(
    routes: [
      // Admin Routes
      ...adminRoutes,

      // Default redirect for any unmatched routes
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(state.error.toString())),
    ),
  );
}
