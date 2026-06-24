import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';

/// Satu tile notifikasi: ikon bulat berwarna, judul, isi, waktu, dan indikator
/// belum-dibaca.
///
/// Tile yang belum dibaca diberi latar biru lembut + titik biru agar mudah
/// dibedakan dari yang sudah dibaca (putih polos).
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final AppNotification notification;

  /// Status baca efektif dikontrol layar (agar "Tandai Semua Dibaca" bekerja),
  /// bukan diambil langsung dari model.
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = notification.type;
    return InkWell(
      onTap: onTap,
      child: Container(
        // Latar menandai status baca; unread sedikit biru.
        color: isRead
            ? AppColors.surface
            : AppColors.primarySoft.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon bulat sesuai jenis notifikasi.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Kolom kanan: waktu + titik unread.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  notification.time,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
