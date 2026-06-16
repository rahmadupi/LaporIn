import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/watch_zone.dart';
import '../../domain/repositories/watch_zone_repository.dart';

/// Status pemuatan daftar Watch Zone.
enum WatchZoneStatus { loading, loaded, error }

/// State management daftar Watch Zone: stream Firestore -> UI. Mutasi (create/
/// update/softDelete) didelegasikan ke repository; snapshots() menyegarkan UI.
class WatchZoneNotifier extends ChangeNotifier {
  WatchZoneNotifier({
    required WatchZoneRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId {
    _subscribe();
  }

  final WatchZoneRepository _repository;
  final String _userId;
  StreamSubscription<List<WatchZone>>? _subscription;

  WatchZoneStatus _status = WatchZoneStatus.loading;
  WatchZoneStatus get status => _status;

  List<WatchZone> _zones = const [];
  List<WatchZone> get zones => _zones;
  int get count => _zones.length;
  bool get isEmpty => _zones.isEmpty;

  String? _error;
  String? get error => _error;

  void _subscribe() {
    _subscription = _repository.watchUserZones(_userId).listen(
      (list) {
        _zones = list;
        _status = WatchZoneStatus.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[WatchZone] Gagal memuat: $e');
        _status = WatchZoneStatus.error;
        _error = 'Gagal memuat Watch Zone.';
        notifyListeners();
      },
    );
  }

  Future<void> delete(String id) async {
    try {
      await _repository.softDelete(id);
    } catch (e) {
      debugPrint('[WatchZone] Gagal menghapus: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
