/// Encoder geohash (base32) ringan, tanpa dependency eksternal.
///
/// Geohash mengubah koordinat (lat,lng) menjadi string pendek yang merepresen-
/// tasikan sebuah sel grid. Disimpan di field `geohash` tiap laporan (skema 8.2)
/// agar fitur lain bisa melakukan geo-query murah: deteksi duplikat radius
/// dekat & Watch Zones cukup membandingkan prefix string, bukan menghitung
/// jarak satu per satu.
class Geohash {
  Geohash._();

  // Alfabet base32 standar geohash (tanpa huruf a, i, l, o agar tak ambigu).
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode [lat]/[lng] ke string geohash sepanjang [precision] karakter.
  ///
  /// Algoritma: bagi-dua bujur & lintang secara bergantian (interleaving bit),
  /// setiap 5 bit menjadi satu karakter base32. Presisi 9 ≈ akurasi ~5 meter,
  /// cukup untuk mendeteksi laporan di lokasi yang sama.
  static String encode(double lat, double lng, {int precision = 9}) {
    var idx = 0; // Indeks 5-bit yang sedang dirakit menjadi satu karakter.
    var bit = 0; // Penghitung bit (0..4) sebelum di-flush ke karakter.
    var evenBit = true; // Bergantian: true = proses bujur, false = lintang.
    var latMin = -90.0, latMax = 90.0;
    var lonMin = -180.0, lonMax = 180.0;
    final geohash = StringBuffer();

    while (geohash.length < precision) {
      if (evenBit) {
        // Persempit rentang bujur ke separuh yang memuat lng.
        final lonMid = (lonMin + lonMax) / 2;
        if (lng >= lonMid) {
          idx = idx * 2 + 1;
          lonMin = lonMid;
        } else {
          idx = idx * 2;
          lonMax = lonMid;
        }
      } else {
        // Persempit rentang lintang ke separuh yang memuat lat.
        final latMid = (latMin + latMax) / 2;
        if (lat >= latMid) {
          idx = idx * 2 + 1;
          latMin = latMid;
        } else {
          idx = idx * 2;
          latMax = latMid;
        }
      }
      evenBit = !evenBit;

      // Setiap 5 bit terkumpul -> ubah jadi satu karakter base32.
      if (++bit == 5) {
        geohash.write(_base32[idx]);
        bit = 0;
        idx = 0;
      }
    }
    return geohash.toString();
  }
}
