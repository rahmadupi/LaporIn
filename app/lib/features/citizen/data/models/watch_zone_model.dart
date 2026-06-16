import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/watch_zone.dart';

/// Serialisasi koleksi `watch_zones/{id}` <-> entitas [WatchZone].
///
/// Skema dokumen: userId, name, latitude, longitude, radius, address,
/// createdAt, updatedAt, isDeleted, deletedAt?
class WatchZoneModel {
  WatchZoneModel._();

  static WatchZone fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return WatchZone(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      radius: (data['radius'] as num?)?.toDouble() ?? 0,
      address: (data['address'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Payload pembuatan zona baru (isDeleted=false).
  static Map<String, dynamic> toCreate({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  }) {
    return {
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'deletedAt': null,
    };
  }

  /// Payload pembaruan (nama/lokasi/radius/alamat). createdAt tidak disentuh.
  static Map<String, dynamic> toUpdate({
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  }) {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
