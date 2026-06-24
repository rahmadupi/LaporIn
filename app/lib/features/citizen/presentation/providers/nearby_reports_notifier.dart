import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  /// Laporan mentah terakhir dari stream, disimpan agar bisa dipetakan ulang
  /// (label jarak + urutan) begitu origin GPS baru tersedia — tanpa menunggu
  /// snapshot Firestore berikutnya.
  List<Report> _lastReports = const [];

  NearbyStatus _status = NearbyStatus.loading;
  NearbyStatus get status => _status;

  List<NearbyReport> _items = const [];
  List<NearbyReport> get items => _items;

  bool get isEmpty => _items.isEmpty;

  double? _originLat;
  double? _originLng;

  /// Posisi GPS pengguna sebagai pusat geofence (null bila izin/GPS tak ada).
  LatLng? get origin => (_originLat != null && _originLng != null)
      ? LatLng(_originLat!, _originLng!)
      : null;

  void _init() {
    // Berlangganan stream Firestore SEGERA agar daftar/peta langsung memuat —
    // TIDAK menunggu GPS (yang bisa lambat/timeout) supaya layar tak menggantung.
    _subscribe();
    // Resolusi GPS berjalan PARALEL. Begitu selesai, jarak dihitung & daftar
    // diurutkan ulang. Sengaja tidak di-await di sini (fire-and-forget).
    unawaited(_resolveOriginThenResort());
  }

  /// Selesaikan origin GPS, lalu petakan ulang laporan terakhir memakai origin
  /// itu (label jarak + urutan terdekat). Aman bila snapshot belum tiba: stream
  /// listener akan memetakan dengan origin terbaru saat data datang.
  Future<void> _resolveOriginThenResort() async {
    await _resolveOrigin();
    if (_originLat == null || _originLng == null) return;
    _applyToItems();
    notifyListeners();
  }

  /// Ambil posisi GPS HANYA bila izin sudah diberikan (tanpa meminta paksa).
  /// `timeLimit` 8 detik mencegah `getCurrentPosition` menggantung tanpa batas
  /// saat sinyal GPS lemah — timeout dilempar sebagai TimeoutException & ditelan
  /// di bawah, sehingga daftar tetap tampil tanpa jarak.
  Future<void> _resolveOrigin() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _originLat = pos.latitude;
      _originLng = pos.longitude;
    } catch (e) {
      // Termasuk TimeoutException saat GPS > 8 dtk: lanjut tanpa jarak.
      debugPrint('[Nearby] Lokasi tidak tersedia: $e');
    }
  }

  void _subscribe() {
    _subscription = _repository.watchPublicReports(limit: 50).listen(
      (reports) {
        _lastReports = reports;
        _applyToItems();
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

  /// Petakan [_lastReports] ke view model dengan origin GPS terkini, lalu
  /// urutkan terdekat dulu bila origin diketahui. Dipanggil tiap snapshot baru
  /// maupun saat GPS baru selesai diresolusi.
  void _applyToItems() {
    final mapped = _lastReports
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
