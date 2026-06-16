import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/admin_scaffold.dart';

/// Placeholder screen for routes whose feature has not been built yet.
///
/// Triggered by tapping a bottom-nav item other than Dashboard, the
/// notification bell, or any shortcut in the dashboard.
class UnderConstructionScreen extends StatelessWidget {
  const UnderConstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentPath: '/admin/under-construction',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.construction,
                  size: 52,
                  color: Color(0xFFCA8A04),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Halaman Sedang Dikembangkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur ini belum tersedia. Silakan kembali lagi nanti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Kembali ke Dashboard'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
