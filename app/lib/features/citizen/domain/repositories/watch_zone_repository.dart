import '../entities/watch_zone.dart';

/// Kontrak CRUD Watch Zone. Implementasi konkret di
/// FirebaseWatchZoneRepository; UI/notifier hanya bergantung pada abstraksi ini.
abstract class WatchZoneRepository {
  /// Stream zona milik [userId] yang belum di-soft-delete (terbaru di atas).
  Stream<List<WatchZone>> watchUserZones(String userId);

  /// Buat zona baru; mengembalikan id dokumen.
  Future<String> create({
    required String userId,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  });

  /// Perbarui nama/lokasi/radius/alamat zona [id].
  Future<void> update({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radius,
    required String address,
  });

  /// Soft delete: set isDeleted=true + deletedAt.
  Future<void> softDelete(String id);
}
