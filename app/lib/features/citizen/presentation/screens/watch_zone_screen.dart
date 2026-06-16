import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../domain/entities/watch_zone.dart';
import '../../domain/repositories/watch_zone_repository.dart';
import '../widgets/radius_slider.dart';

/// Atur Watch Zone (buat / edit) — TERSIMPAN ke Firestore `watch_zones`.
///
/// Warga memilih pusat zona dengan menggeser peta (pin tetap di tengah),
/// menamai zona, dan menentukan radius. Pratinjau menampilkan jumlah laporan
/// aktif NYATA di area (dihitung saat peta berhenti digeser). Saat disimpan,
/// alamat pusat di-reverse-geocode lalu dokumen dibuat/diperbarui.
///
/// TAHAN-BANTING: GoogleMap tetap dirender walau API key Maps belum dipasang
/// (tile kosong, tidak crash). [existing] != null berarti mode edit.
class WatchZoneScreen extends StatefulWidget {
  const WatchZoneScreen({super.key, this.onClose, this.existing});

  /// Aksi tombol kembali / tutup. Bila null, tombol disembunyikan.
  final VoidCallback? onClose;

  /// Zona yang sedang diedit; null = buat zona baru.
  final WatchZone? existing;

  @override
  State<WatchZoneScreen> createState() => _WatchZoneScreenState();
}

class _WatchZoneScreenState extends State<WatchZoneScreen> {
  // Pusat awal: Sidoarjo, selaras lokasi default Beranda.
  static const LatLng _initialCenter = LatLng(-7.4478, 112.7183);
  static const double _minRadius = 100;
  static const double _maxRadius = 5000;

  final _nameController = TextEditingController();
  final _geocoder = const GeocodingService();
  GoogleMapController? _mapController;

  late LatLng _center;
  late double _radius;

  int? _activeNearby; // Jumlah laporan aktif nyata di area (null = belum dihitung).
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _center = e != null ? LatLng(e.latitude, e.longitude) : _initialCenter;
    _radius = e?.radius ?? 500;
    if (e != null) _nameController.text = e.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Hitung laporan aktif nyata dalam radius (dipanggil saat kamera berhenti).
  Future<void> _refreshNearbyCount() async {
    try {
      final reports =
          await context.read<ReportsRepository>().nearbyActiveReports(
                latitude: _center.latitude,
                longitude: _center.longitude,
                radiusMeters: _radius,
              );
      if (mounted) setState(() => _activeNearby = reports.length);
    } catch (e) {
      debugPrint('[WatchZone] Gagal menghitung laporan terdekat: $e');
    }
  }

  /// Pindahkan kamera ke lokasi GPS pengguna; tahan-banting bila izin/GPS gagal.
  Future<void> _goToCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _notify('Aktifkan GPS untuk memakai lokasi saat ini.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _notify('Izin lokasi ditolak.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
      setState(() => _center = target);
    } catch (_) {
      _notify('Gagal mengambil lokasi saat ini.');
    }
  }

  void _notify(String message) {
    if (mounted) SnackbarHelper.showError(context, message);
  }

  /// Validasi nama lalu simpan ke Firestore (create/update).
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return SnackbarHelper.showError(context, 'Beri nama zona terlebih dulu.');
    }
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null || uid.isEmpty) {
      return SnackbarHelper.showError(context, 'Sesi berakhir, silakan login.');
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final repo = context.read<WatchZoneRepository>();
    try {
      // Reverse geocoding pusat zona untuk disimpan sebagai alamat (External API).
      final address =
          await _geocoder.resolveAddress(_center.latitude, _center.longitude);

      if (_isEdit) {
        await repo.update(
          id: widget.existing!.id,
          name: name,
          latitude: _center.latitude,
          longitude: _center.longitude,
          radius: _radius,
          address: address,
        );
      } else {
        await repo.create(
          userId: uid,
          name: name,
          latitude: _center.latitude,
          longitude: _center.longitude,
          radius: _radius,
          address: address,
        );
      }

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'Watch Zone "$name" (${RadiusSlider.formatRadius(_radius)}) disimpan.',
      );
      widget.onClose?.call();
    } catch (e) {
      debugPrint('[WatchZone] Gagal menyimpan: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Gagal menyimpan Watch Zone.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          const Positioned.fill(
            child: Align(
              alignment: Alignment(0, -0.22),
              child: _CenterPin(),
            ),
          ),
          _buildTopOverlay(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 16),
                  child: _CurrentLocationButton(onTap: _goToCurrentLocation),
                ),
                _buildBottomSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Peta latar. Pusat zona mengikuti kamera; saat berhenti -> hitung laporan.
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _center, zoom: 14),
      onMapCreated: (c) => _mapController = c,
      onCameraMove: (pos) => _center = pos.target,
      onCameraIdle: _refreshNearbyCount,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
      circles: {
        Circle(
          circleId: const CircleId('watch_zone_radius'),
          center: _center,
          radius: _radius,
          fillColor: AppColors.primary.withValues(alpha: 0.18),
          strokeColor: AppColors.primary.withValues(alpha: 0.45),
          strokeWidth: 2,
        ),
      },
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              _FloatingSearchBar(onBack: widget.onClose),
              const SizedBox(height: 12),
              const _HintBanner(text: '💡 Geser peta untuk memilih pusat zona'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2C6D3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Edit Watch Zone' : 'Atur Watch Zone',
                    style: const TextStyle(
                      fontSize: 22,
                      height: 30 / 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      onPressed: widget.onClose,
                      iconSize: 20,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Tutup',
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 24),
              RadiusSlider(
                value: _radius,
                min: _minRadius,
                max: _maxRadius,
                onChanged: (v) => setState(() => _radius = v),
                onChangeEnd: (_) => _refreshNearbyCount(),
              ),
              const SizedBox(height: 24),
              _ActivityPreview(text: _previewText()),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _saving ? 'Menyimpan...' : 'Simpan Watch Zone',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Teks pratinjau berbasis data NYATA (bukan estimasi dummy).
  String _previewText() {
    if (_activeNearby == null) {
      return '📊 Menghitung laporan aktif di area ini...';
    }
    if (_activeNearby == 0) {
      return '📊 Belum ada laporan aktif di area ini saat ini';
    }
    return '📊 Ada $_activeNearby laporan aktif di area ini';
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nama Zona',
          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Rumah, Kantor, dll',
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            border: _fieldBorder(AppColors.border),
            enabledBorder: _fieldBorder(AppColors.border),
            focusedBorder: _fieldBorder(AppColors.primary, width: 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Pin pusat zona yang tetap di tengah layar saat peta digeser.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on,
          size: 44,
          color: AppColors.primary,
          shadows: [
            Shadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Bar pencarian mengambang: tombol kembali + field pencarian lokasi.
///
/// Field bersifat dekoratif (pemilihan pusat zona dilakukan dengan menggeser
/// peta). Tombol kembali memanggil [onBack].
class _FloatingSearchBar extends StatelessWidget {
  const _FloatingSearchBar({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            ),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'Geser peta untuk memilih lokasi',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner petunjuk biru muda di bawah bar pencarian.
class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD6E3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF00458D),
        ),
      ),
    );
  }
}

/// Tombol bulat mengambang "lokasi saat ini" di atas bottom sheet.
class _CurrentLocationButton extends StatelessWidget {
  const _CurrentLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.my_location, size: 22, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Kartu pratinjau jumlah laporan aktif di area zona (data nyata).
class _ActivityPreview extends StatelessWidget {
  const _ActivityPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}
