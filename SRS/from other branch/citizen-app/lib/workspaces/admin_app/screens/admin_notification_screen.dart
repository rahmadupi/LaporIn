import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/ui/notification_screen.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

/// Halaman notifikasi khusus Admin. Membungkus [NotificationScreen] dengan
/// callback yang relevan untuk role admin (logout, deep-link ke laporan).
class AdminNotificationScreen extends ConsumerWidget {
  const AdminNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationScreen(
      roleLabel: 'Admin',
      availableTypes: const [
        NotificationType.laporanBaru,
        NotificationType.statusBerubah,
        NotificationType.komentarBaru,
        NotificationType.slaBreach,
        NotificationType.banding,
        NotificationType.system,
      ],
      onNotificationTap: (n) {
        // TODO: deep-link ke ReportDetailScreen(n.reportId) atau halaman
        // banding saat tersedia. Untuk sekarang, return false agar tetap
        // menampilkan SnackBar konfirmasi.
        return false;
      },
      onLogout: () async {
        await ref.read(authRepositoryProvider).signOut();
        await ref.read(currentUserProvider.notifier).refresh();
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          context.go(AppRoutes.splash);
        }
      },
    );
  }
}