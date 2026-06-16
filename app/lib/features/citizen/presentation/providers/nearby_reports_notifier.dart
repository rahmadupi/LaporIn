import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/geo_distance.dart';
import '../../../reports/domain/entities/report.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../models/nearby_report.dart';

/// Status pemuatan "Laporan Terdekat".
enum NearbyStatus { loading, loaded, error }

/// Menyediakan daftar laporan publik terbaru (Beranda & Peta) dari Firestore,
/// dipetakan ke [NearbyReport]. Bila izin lokasi sudah diberikan, jarak tiap
/// laporan dihitung dari posisi GPS dan daftar diurutkan terdekat lebih dulu.
///
/// Tidak memunculkan dialog izin lokasi sendiri (agar Beranda tidak intrusif) —
/// hanya memakai izin yang SUDAH ada; jika belum, jarak ditampilkan netral.
class NearbyReportsNotifier extends ChangeNotifier {
  NearbyReportsNotifier({required ReportsRepository repository})
      : _repository = repository {
    _init();
  }

  final ReportsRepository _repository;
  StreamSubscription<List<Report>>? _subscription;

  NearbyStatus _status = NearbyStatus.loading;
  NearbyStatus get status => _status;

  List<NearbyReport> _items = const [];
  List<NearbyReport> get items => _items;

  bool get isEmpty => _items.isEmpty;

  double? _originLat;
  double? _originLng;

  Future<void> _init() async {
    await _resolveOrigin();
    _subscribe();
  }

  /// Ambil posisi GPS HANYA bila izin sudah diberikan (tanpa meminta paksa).
  Future<void> _resolveOrigin() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      _originLat = pos.latitude;
      _originLng = pos.longitude;
    } catch (e) {
      debugPrint('[Nearby] Lokasi tidak tersedia: $e');
    }
  }

  void _subscribe() {
    _subscription = _repository.watchPublicReports(limit: 50).listen(
      (reports) {
        final mapped = reports
            .map((r) => NearbyReport.fromReport(
                  r,
                  originLat: _originLat,
                  originLng: _originLng,
                ))
            .toList();

        // Urutkan terdekat dulu bila origin diketahui (label "Sekitar" -> akhir).
        if (_originLat != null && _originLng != null) {
          mapped.sort((a, b) => _distMeters(a).compareTo(_distMeters(b)));
        }

        _items = mapped;
        _status = NearbyStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[Nearby] Gagal memuat laporan publik: $e');
        _status = NearbyStatus.error;
        notifyListeners();
      },
    );
  }

  double _distMeters(NearbyReport r) {
    final loc = r.location;
    if (loc == null || _originLat == null || _originLng == null) {
      return double.maxFinite;
    }
    return GeoDistance.meters(
        _originLat!, _originLng!, loc.latitude, loc.longitude);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
