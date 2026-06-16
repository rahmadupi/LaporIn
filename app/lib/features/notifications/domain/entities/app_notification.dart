import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Jenis notifikasi — menentukan ikon & warna lingkaran di tile.
///
/// [slug] adalah nilai yang disimpan di field `type` Firestore (stabil walau
/// label/ikon UI berubah). Slug tak dikenal jatuh ke [info] agar UI tak crash.
enum NotificationType {
  statusUpdate('status_update', Icons.update, AppColors.primary),
  completed('completed', Icons.check_circle, AppColors.success),
  assignment('assignment', Icons.warning_amber_rounded, AppColors.accent),
  info('info', Icons.info_outline, AppColors.primary);

  const NotificationType(this.slug, this.icon, this.color);
  final String slug;
  final IconData icon;
  final Color color;

  static NotificationType fromSlug(String? value) {
    return values.firstWhere(
      (t) => t.slug == value,
      orElse: () => NotificationType.info,
    );
  }
}

/// Satu item notifikasi yang dibaca dari koleksi `notifications` Firestore.
///
/// [reportId] opsional: bila ada, mengetuk notifikasi membuka Detail Laporan
/// terkait — sama seperti perilaku deep link push notification FCM.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.reportId,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;

  /// Waktu pembuatan (server). Diformat ke teks relatif saat ditampilkan.
  final DateTime? createdAt;
  final String? reportId;
}
