import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin_bottom_nav_bar.dart';

/// Common scaffold for the admin workspace.
///
/// Provides the shared LaporIn header (logo + notification bell) and the
/// bottom navigation bar. Screens that need to render above the bottom nav
/// can simply use this widget as their root.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.child,
    this.currentPath,
    this.showAppHeader = true,
  });

  /// The main content of the screen, rendered between the optional header and
  /// the bottom navigation bar.
  final Widget child;

  /// Path used to highlight the correct bottom-nav destination. Defaults to
  /// `/admin` (Dashboard) when omitted.
  final String? currentPath;

  /// Whether to render the LaporIn header (logo + bell) above the body.
  final bool showAppHeader;

  void _goToUnderConstruction(BuildContext context) {
    context.go('/admin/under-construction');
  }

  @override
  Widget build(BuildContext context) {
    final matched = GoRouterState.of(context).matchedLocation;
    final path = currentPath ?? (matched.isEmpty ? '/admin' : matched);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showAppHeader)
              _AdminHeader(
                onNotificationTap: () => _goToUnderConstruction(context),
              ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavBar(currentPath: path),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          // Logo cluster: blue icon + LaporIn wordmark
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LaporIn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotificationTap,
            icon: Icon(
              Icons.notifications_none,
              color: Colors.grey.shade700,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
