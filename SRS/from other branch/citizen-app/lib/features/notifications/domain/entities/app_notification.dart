import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Jenis notifikasi — menentukan ikon & warna lingkaran di tile.
enum NotificationType {
  statusUpdate(Icons.update, AppColors.primary),
  completed(Icons.check_circle, AppColors.success),
  assignment(Icons.warning_amber_rounded, AppColors.accent),
  info(Icons.info_outline, AppColors.primary);

  const NotificationType(this.icon, this.color);
  final IconData icon;
  final Color color;
}

/// Model DUMMY satu item notifikasi di Notification Center.
///
/// [reportId] opsional: bila ada, mengetuk notifikasi membuka Detail Laporan
/// terkait — sama seperti perilaku deep link dari push notification FCM.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
    this.reportId,
  });

  final String id;
  final String title;
  final String body;

  /// Label waktu yang sudah diformat untuk tampilan (mis. "10:30", "Selasa").
  final String time;
  final NotificationType type;
  final bool isRead;
  final String? reportId;
}

/// Satu kelompok notifikasi berdasarkan waktu (mis. "Hari Ini").
class NotificationGroup {
  const NotificationGroup({required this.label, required this.items});

  final String label;
  final List<AppNotification> items;

  /// Data contoh statis sesuai mockup Notification Center.
  static const List<NotificationGroup> dummyGroups = [
    NotificationGroup(
      label: 'Hari Ini',
      items: [
        AppNotification(
          id: 'n1',
          title: 'Status Laporan Diperbarui',
          body: 'Laporan LPR-2026-0001234 sedang ditinjau oleh petugas.',
          time: '10:30',
          type: NotificationType.statusUpdate,
          reportId: 'LPR-2026-0001234', // Bisa di-tap menuju detail.
        ),
        AppNotification(
          id: 'n2',
          title: 'Laporan Selesai',
          body: 'Perbaikan jalan di Jl. Diponegoro telah selesai dilakukan. '
              'Lihat hasilnya!',
          time: '08:15',
          type: NotificationType.completed,
          isRead: true,
          reportId: 'LPR-2026-0001234',
        ),
      ],
    ),
    NotificationGroup(
      label: 'Kemarin',
      items: [
        AppNotification(
          id: 'n3',
          title: 'Tugas Baru Menunggu',
          body: 'Anda ditugaskan untuk memvalidasi pengerjaan di UPT Selatan.',
          time: '14:20',
          type: NotificationType.assignment,
        ),
      ],
    ),
    NotificationGroup(
      label: 'Minggu Ini',
      items: [
        AppNotification(
          id: 'n4',
          title: 'Tips LaporIn',
          body: 'Gunakan fitur Watch Zone untuk memantau keamanan di sekitar '
              'rumah Anda.',
          time: 'Selasa',
          type: NotificationType.info,
          isRead: true,
        ),
      ],
    ),
  ];
}
