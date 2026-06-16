import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/presentation/screens/report_detail_screen.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../providers/notification_list_notifier.dart';
import '../widgets/notification_tile.dart';

/// Notification Center (Citizen) — data REAL dari koleksi `notifications`.
///
/// Menyediakan [NotificationListNotifier] (yang membuka stream Firestore) hanya
/// selama layar hidup. Mendukung Read (daftar), Update (tandai dibaca / tandai
/// semua), dan soft Delete (geser kartu). Mengetuk notifikasi membuka Detail
/// Laporan bila ada reportId — cerminan deep link push notification FCM.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return ChangeNotifierProvider(
      create: (ctx) => NotificationListNotifier(
        repository: ctx.read<NotificationRepository>(),
        userId: uid,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          actions: const [_MarkAllButton()],
        ),
        body: const _NotificationBody(),
      ),
    );
  }
}

/// Tombol "Tandai Semua Dibaca" — nonaktif bila tidak ada yang belum dibaca.
class _MarkAllButton extends StatelessWidget {
  const _MarkAllButton();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotificationListNotifier>();
    final enabled = notifier.hasUnread;
    return TextButton(
      onPressed: enabled ? notifier.markAllRead : null,
      child: Text(
        'Tandai Semua Dibaca',
        style: TextStyle(
          color: enabled ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotificationListNotifier>();

    switch (notifier.status) {
      case NotificationsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case NotificationsStatus.error:
        return _CenteredMessage(
          icon: Icons.cloud_off,
          message: notifier.error ?? 'Terjadi kesalahan.',
        );
      case NotificationsStatus.loaded:
        if (notifier.isEmpty) {
          return const _CenteredMessage(
            icon: Icons.notifications_none,
            message: 'Belum ada notifikasi.',
          );
        }
        return ListView.builder(
          itemCount: notifier.items.length,
          itemBuilder: (context, index) {
            final n = notifier.items[index];
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(),
              onDismissed: (_) => notifier.delete(n.id),
              child: NotificationTile(
                notification: n,
                isRead: n.isRead,
                onTap: () => _onTap(context, notifier, n),
              ),
            );
          },
        );
    }
  }

  /// Tap: tandai dibaca, lalu buka Detail Laporan bila ada reportId.
  void _onTap(
    BuildContext context,
    NotificationListNotifier notifier,
    AppNotification n,
  ) {
    if (!n.isRead) notifier.markRead(n.id);
    final reportId = n.reportId;
    if (reportId == null || reportId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(reportId: reportId),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      color: AppColors.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}

/// Tampilan tengah untuk kondisi kosong/error.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
