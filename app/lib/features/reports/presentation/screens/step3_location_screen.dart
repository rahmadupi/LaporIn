import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/report_form_notifier.dart';
import '../widgets/report_step_scaffold.dart';

/// Status proses pengambilan lokasi, untuk menentukan tampilan body.
enum _LocStatus { loading, ready, denied, error }

/// Lapor Step 3 — Pin Lokasi (geolocator + geocoding + google_maps_flutter).
///
/// Dirancang TAHAN-BANTING: peta hanya pelengkap. Sumber kebenaran lokasi
/// adalah GPS (geolocator) + alamat hasil reverse geocoding (geocoding). Jika
/// API key Maps belum dipasang, peta tampil kosong TANPA membuat layar crash;
/// koordinat & alamat tetap terisi dan tombol "Lanjut" tetap berfungsi.
class Step3LocationScreen extends StatefulWidget {
  const Step3LocationScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step3LocationScreen> createState() => _Step3LocationScreenState();
}

class _Step3LocationScreenState extends State<Step3LocationScreen> {
  _LocStatus _status = _LocStatus.loading;
  String _message = ''; // Pesan saat denied/error.

  GoogleMapController? _mapController;
  LatLng? _picked; // Titik yang dipilih (dari GPS atau geser pin).
  String _address = 'Mencari alamat...';

  @override
  void initState() {
    super.initState();
    _initLocation(); // Otomatis ambil lokasi saat layar dibuka.
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Alur perizinan + pengambilan GPS (mengikuti pola resmi geolocator).
  Future<void> _initLocation() async {
    setState(() => _status = _LocStatus.loading);

    // 1) Pastikan layanan lokasi (GPS) perangkat menyala.
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return _fail(_LocStatus.denied,
          'Layanan lokasi mati. Aktifkan GPS lalu coba lagi.');
    }

    // 2) Cek & minta izin lokasi bila perlu.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return _fail(_LocStatus.denied, 'Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      return _fail(_LocStatus.denied,
          'Izin lokasi diblokir permanen. Aktifkan lewat Pengaturan.');
    }

    // 3) Ambil posisi sekarang lalu pasang sebagai titik awal.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      await _setPoint(LatLng(pos.latitude, pos.longitude));
      setState(() => _status = _LocStatus.ready);
    } catch (_) {
      _fail(_LocStatus.error, 'Gagal mengambil lokasi. Coba lagi.');
    }
  }

  void _fail(_LocStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _message = message;
    });
  }

  /// Set titik terpilih: simpan ke notifier, geser kamera, lalu reverse-geocode.
  Future<void> _setPoint(LatLng point) async {
    _picked = point;
    // Simpan koordinat lebih dulu (tanpa menunggu geocoding) supaya tombol
    // "Lanjut" langsung aktif walau alamat masih diproses.
    context.read<ReportFormNotifier>().setLocation(
          latitude: point.latitude,
          longitude: point.longitude,
          address: _address,
        );
    _mapController?.animateCamera(CameraUpdate.newLatLng(point));
    await _reverseGeocode(point);
  }

  /// Reverse geocoding: ubah koordinat menjadi alamat yang dibaca manusia.
  ///
  /// Dibungkus try/catch karena layanan geocoding bisa gagal (offline, tidak
  /// ada hasil, atau tak tersedia di platform). Bila gagal, alamat fallback ke
  /// koordinat mentah agar laporan tetap punya nilai `address` yang valid.
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (!mounted) return;
      final address = placemarks.isNotEmpty
          ? _formatPlacemark(placemarks.first)
          : _coordsText(point);
      _commitAddress(address);
    } catch (_) {
      _commitAddress(_coordsText(point));
    }
  }

  /// Rangkai field placemark menjadi satu baris alamat, abaikan bagian kosong.
  String _formatPlacemark(Placemark p) {
    final parts = [
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
    ].where((e) => e != null && e.trim().isNotEmpty).toList();
    return parts.isEmpty ? _coordsText(_picked!) : parts.join(', ');
  }

  String _coordsText(LatLng p) =>
      'Lat ${p.latitude.toStringAsFixed(5)}, Lng ${p.longitude.toStringAsFixed(5)}';

  /// Simpan alamat final ke state lokal + notifier.
  void _commitAddress(String address) {
    if (!mounted || _picked == null) return;
    setState(() => _address = address);
    context.read<ReportFormNotifier>().setLocation(
          latitude: _picked!.latitude,
          longitude: _picked!.longitude,
          address: address,
        );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportFormNotifier>();

    return ReportStepScaffold(
      currentStep: 3,
      title: 'Pin Lokasi',
      subtitle: 'Geser pin atau ketuk peta untuk menyesuaikan titik kerusakan.',
      primaryLabel: 'Lanjut',
      onBack: widget.onBack,
      onPrimary: notifier.isStep3Valid ? widget.onNext : null,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _LocStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _LocStatus.denied:
      case _LocStatus.error:
        return _LocationProblem(message: _message, onRetry: _initLocation);
      case _LocStatus.ready:
        return _buildMapView();
    }
  }

  Widget _buildMapView() {
    final point = _picked!;
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            // GoogleMap tetap dirender meski API key belum ada: tile-nya kosong,
            // tapi tidak crash. Interaksi pin tetap memperbarui koordinat.
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: point, zoom: 16),
              onMapCreated: (c) => _mapController = c,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onTap: (latLng) => _setPoint(latLng),
              markers: {
                Marker(
                  markerId: const MarkerId('report_location'),
                  position: point,
                  draggable: true,
                  onDragEnd: (latLng) => _setPoint(latLng),
                ),
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Kartu alamat hasil reverse geocoding + tombol pakai lokasi sekarang.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _address,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                tooltip: 'Gunakan lokasi saat ini',
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                onPressed: _initLocation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tampilan saat izin ditolak / GPS mati / gagal — dengan tombol coba lagi.
class _LocationProblem extends StatelessWidget {
  const _LocationProblem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off,
              size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
