import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The four primary destinations for the admin app, shown in the bottom
/// navigation bar.
enum AdminNavDestination {
  dashboard('/admin', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  laporan(
    '/admin/laporan',
    Icons.description_outlined,
    Icons.description,
    'Moderation',
  ),
  petugas('/admin/petugas', Icons.badge_outlined, Icons.badge, 'Petugas'),
  profil('/admin/profil', Icons.person_outline, Icons.person, 'Profil');

  const AdminNavDestination(
    this.routePath,
    this.icon,
    this.activeIcon,
    this.label,
  );

  final String routePath;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// A reusable bottom navigation bar for the admin workspace.
///
/// Tapping an item routes the user to the destination's primary path. Items
/// that are not yet implemented are routed to the under-construction page.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key, required this.currentPath});

  final String currentPath;

  int _indexFromPath(String path) {
    for (var i = 0; i < AdminNavDestination.values.length; i++) {
      final dest = AdminNavDestination.values[i];
      if (path == dest.routePath ||
          (dest == AdminNavDestination.dashboard && path == '/admin')) {
        return i;
      }
    }
    // Default highlight to Dashboard for unknown paths.
    return AdminNavDestination.dashboard.index;
  }

  void _onTap(BuildContext context, int index) {
    final dest = AdminNavDestination.values[index];
    if (dest == AdminNavDestination.dashboard) {
      context.go(dest.routePath);
      return;
    }
    // All non-dashboard destinations are placeholders for now.
    context.go('/admin/under-construction');
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _indexFromPath(currentPath);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: Colors.white,
          indicatorColor: Colors.blue.withValues(alpha: 0.12),
          height: 68,
          destinations: [
            for (final dest in AdminNavDestination.values)
              NavigationDestination(
                icon: Icon(dest.icon, color: Colors.grey.shade600),
                selectedIcon: Icon(
                  dest.activeIcon,
                  color: Colors.blue.shade700,
                ),
                label: dest.label,
              ),
          ],
        ),
      ),
    );
  }
}
