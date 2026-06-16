import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/app_notification.dart';

/// Serialisasi koleksi `notifications/{id}` <-> entitas [AppNotification].
///
/// Skema dokumen:
///   userId, title, message, reportId?, type, isRead, createdAt, updatedAt,
///   isDeleted, deletedAt?
class NotificationModel {
  NotificationModel._();

  static AppNotification fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      type: NotificationType.fromSlug(data['type'] as String?),
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      reportId: data['reportId'] as String?,
    );
  }

  /// Payload pembuatan notifikasi (dipakai backend/seeding). Status awal:
  /// belum dibaca & belum dihapus.
  static Map<String, dynamic> toFirestore({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? reportId,
  }) {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.slug,
      'reportId': reportId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedAt': null,
    };
  }
}
