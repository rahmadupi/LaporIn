import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reports/presentation/screens/report_detail_screen.dart';
import '../../domain/entities/app_notification.dart';
import '../widgets/notification_tile.dart';

/// Notification Center (Citizen).
///
/// Menampilkan notifikasi DUMMY yang dikelompokkan per waktu (Hari Ini, Kemarin,
/// Minggu Ini). StatefulWidget karena menyimpan himpunan id yang sudah dibaca
/// agar fitur "Tandai Semua Dibaca" & tap-untuk-baca bekerja secara lokal.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const _groups = NotificationGroup.dummyGroups;

  // Id notifikasi yang sudah dibaca. Diinisialisasi dari flag isRead di dummy.
  late final Set<String> _readIds = {
    for (final group in _groups)
      for (final n in group.items)
        if (n.isRead) n.id,
  };

  void _markAllRead() {
    setState(() {
      for (final group in _groups) {
        for (final n in group.items) {
          _readIds.add(n.id);
        }
      }
    });
  }

  /// Tap notifikasi: tandai dibaca, lalu buka Detail bila ada reportId
  /// (perilaku ini cerminan deep link dari push notification FCM).
  void _onTap(AppNotification notification) {
    setState(() => _readIds.add(notification.id));
    final reportId = notification.reportId;
    if (reportId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(reportId: reportId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Tandai Semua Dibaca',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        children: [
          for (final group in _groups) ...[
            _GroupHeader(label: group.label),
            for (final notification in group.items)
              NotificationTile(
                notification: notification,
                isRead: _readIds.contains(notification.id),
                onTap: () => _onTap(notification),
              ),
          ],
        ],
      ),
    );
  }
}

/// Header kelompok waktu (mis. "Hari Ini").
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
