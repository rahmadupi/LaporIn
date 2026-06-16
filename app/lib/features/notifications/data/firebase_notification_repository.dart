import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/app_notification.dart';
import '../domain/repositories/notification_repository.dart';
import 'notification_model.dart';

/// Implementasi [NotificationRepository] di atas Cloud Firestore.
class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    // Notifikasi milik user, sembunyikan yang sudah soft-deleted, terbaru dulu.
    return _col
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(NotificationModel.fromFirestore).toList());
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _col.doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    // Ambil yang belum dibaca lalu tandai dibaca dalam satu batch atomik.
    final unread = await _col
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> softDelete(String notificationId) {
    return _col.doc(notificationId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
