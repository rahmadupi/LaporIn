import 'package:cloud_firestore/cloud_firestore.dart';

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
    return _col
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(WatchZoneModel.fromFirestore).toList());
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
