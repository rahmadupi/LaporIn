import 'package:flutter/material.dart';
import 'package:laporin/core/theme/app_colors.dart';

/// Halaman "Under Construction" generik untuk role-based tabs.
class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({
    super.key,
    required this.role,
    required this.pageName,
  });

  final String role;
  final String pageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.construction,
              size: 52,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Under Construction',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$role - $pageName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Halaman ini sedang dikembangkan.\nSilakan kembali lagi nanti.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
