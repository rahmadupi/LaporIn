import 'dart:math';

/// Penghitung jarak antar koordinat (haversine) tanpa dependency eksternal.
///
/// Dipakai untuk filtering "laporan terdekat" & aktivitas Watch Zone di sisi
/// klien: Firestore tidak mendukung radius-query bawaan, jadi kandidat diambil
/// lalu disaring jaraknya di aplikasi.
class GeoDistance {
  GeoDistance._();

  static const double _earthRadiusMeters = 6371000;

  /// Jarak garis-lurus (meter) antara dua titik lat/lng.
  static double meters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return _earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Format jarak ringkas untuk UI: "120 m", "0.5 km", "2.0 km".
  static String format(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _toRad(double deg) => deg * pi / 180;
}
