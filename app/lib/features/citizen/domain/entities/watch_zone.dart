/// Entitas Watch Zone: area yang dipantau warga agar mendapat info laporan baru
/// di sekitarnya. Dibaca dari koleksi `watch_zones` (sudah bersih dari tipe
/// Firebase — Timestamp/GeoPoint dikonversi di layer model).
class WatchZone {
  const WatchZone({
    required this.id,
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.address,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final double latitude;
  final double longitude;

  /// Radius pantauan dalam meter.
  final double radius;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
