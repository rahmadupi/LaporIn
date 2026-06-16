import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

/// Pembungkus reverse geocoding (External API) dengan penanganan error.
///
/// Mengubah koordinat menjadi alamat yang terbaca manusia. Bila layanan gagal
/// (offline / tak ada hasil), mengembalikan fallback koordinat agar pemanggil
/// selalu menerima string non-null dan UI tidak kosong.
class GeocodingService {
  const GeocodingService();

  /// Resolusi [latitude],[longitude] ke alamat ringkas. Tidak pernah melempar.
  Future<String> resolveAddress(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return _fallback(latitude, longitude);
      return _format(placemarks.first, latitude, longitude);
    } catch (e) {
      debugPrint('[Geocoding] Gagal resolve alamat: $e');
      return _fallback(latitude, longitude);
    }
  }

  String _format(Placemark p, double lat, double lng) {
    // Susun dari bagian yang tersedia; buang yang kosong agar rapi.
    final parts = <String>[
      if ((p.street ?? '').isNotEmpty) p.street!,
      if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
      if ((p.locality ?? '').isNotEmpty) p.locality!,
    ];
    if (parts.isEmpty) return _fallback(lat, lng);
    return parts.join(', ');
  }

  String _fallback(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
