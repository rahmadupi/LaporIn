import '../entities/app_notification.dart';

/// Kontrak operasi notifikasi in-app (Read + Update + soft Delete).
///
/// Implementasi konkret di FirebaseNotificationRepository; UI/notifier hanya
/// bergantung pada abstraksi ini (tidak menyentuh Firestore langsung).
abstract class NotificationRepository {
  /// Stream notifikasi milik [userId] yang belum di-soft-delete, terbaru di
  /// atas (orderBy createdAt desc).
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Tandai satu notifikasi sebagai sudah dibaca.
  Future<void> markAsRead(String notificationId);

  /// Tandai semua notifikasi (yang belum dibaca) milik [userId] sebagai dibaca.
  Future<void> markAllAsRead(String userId);

  /// Soft delete: set isDeleted=true + deletedAt (dokumen tetap untuk audit).
  Future<void> softDelete(String notificationId);
}
