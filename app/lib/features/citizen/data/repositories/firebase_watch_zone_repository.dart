import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/recency_sort.dart';
import '../../domain/entities/watch_zone.dart';
import '../../domain/repositories/watch_zone_repository.dart';
import '../models/watch_zone_model.dart';

/// Implementasi [WatchZoneRepository] di atas Cloud Firestore.
class FirebaseWatchZoneRepository implements WatchZoneRepository {
  FirebaseWatchZoneRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('watch_zones');

  @override
  Stream<List<WatchZone>> watchUserZones(String userId) {
    // Hanya dua filter kesetaraan (userId + isDeleted) TANPA orderBy: kombinasi
    // ini dilayani single-field index bawaan, jadi TIDAK butuh composite index.
    // Sebelumnya `.orderBy('createdAt')` membuat kueri butuh composite index;
    // bila index itu belum di-deploy, stream gagal (FAILED_PRECONDITION) dan UI
    // menampilkan "Gagal memuat". Pengurutan kini dilakukan di klien. Bonus:
    // zona yang baru dibuat (createdAt server-timestamp masih null saat pending
    // write) tetap muncul — dan diletakkan paling atas — tanpa menunggu server.
    return _col
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final zones = snap.docs.map(WatchZoneModel.fromFirestore).toList();
      zones.sort((a, b) => compareByDateDesc(a.createdAt, b.createdAt));
      return zones;
    });
  }

  @override
  Future<String> create({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  }) async {
    final ref = await _col.add(
      WatchZoneModel.toCreate(
        userId: userId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        address: address,
      ),
    );
    return ref.id;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  }) {
    return _col.doc(id).update(
          WatchZoneModel.toUpdate(
            name: name,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            address: address,
          ),
        );
  }

  @override
  Future<void> softDelete(String id) {
    return _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
