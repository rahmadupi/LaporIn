import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../shared/ui/notification_screen.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

/// Halaman notifikasi khusus Warga. Membungkus [NotificationScreen] dengan
/// tipe notifikasi yang relevan untuk citizen (status update laporan
/// sendiri, komentar admin, banding, sistem).
class CitizenNotificationScreen extends ConsumerWidget {
  const CitizenNotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationScreen(
      roleLabel: 'Warga',
      availableTypes: const [
        NotificationType.statusBerubah,
        NotificationType.komentarBaru,
        NotificationType.banding,
        NotificationType.system,
      ],
      onNotificationTap: (n) {
        // TODO: deep-link ke ReportDetailScreen(n.reportId) atau ke
        // ReportHistoryScreen untuk banding. Return false untuk sementara.
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