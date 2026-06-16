import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Status pemuatan daftar notifikasi untuk UI.
enum NotificationsStatus { loading, loaded, error }

/// State management Notification Center: menjembatani stream Firestore ke UI.
///
/// Membuka satu listener real-time ke koleksi `notifications` milik user yang
/// login. Mutasi (markRead/markAll/softDelete) didelegasikan ke repository;
/// karena memakai snapshots(), perubahan langsung mengalir balik ke daftar.
class NotificationListNotifier extends ChangeNotifier {
  NotificationListNotifier({
    required NotificationRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId {
    _subscribe();
  }

  final NotificationRepository _repository;
  final String _userId;
  StreamSubscription<List<AppNotification>>? _subscription;

  NotificationsStatus _status = NotificationsStatus.loading;
  NotificationsStatus get status => _status;

  List<AppNotification> _items = const [];
  List<AppNotification> get items => _items;

  String? _error;
  String? get error => _error;

  bool get hasUnread => _items.any((n) => !n.isRead);
  bool get isEmpty => _items.isEmpty;

  void _subscribe() {
    _subscription = _repository.watchUserNotifications(_userId).listen(
      (list) {
        _items = list;
        _status = NotificationsStatus.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        // Penyebab umum: composite index belum dibuat (lihat firestore.indexes.json).
        debugPrint('[Notifikasi] Gagal memuat: $e');
        _status = NotificationsStatus.error;
        _error = 'Gagal memuat notifikasi.';
        notifyListeners();
      },
    );
  }

  /// Tandai satu notifikasi dibaca (best-effort; stream akan menyegarkan UI).
  Future<void> markRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e) {
      debugPrint('[Notifikasi] Gagal tandai dibaca: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllAsRead(_userId);
    } catch (e) {
      debugPrint('[Notifikasi] Gagal tandai semua dibaca: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.softDelete(id);
    } catch (e) {
      debugPrint('[Notifikasi] Gagal menghapus: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
