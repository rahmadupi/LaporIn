import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/nearby_report.dart';
import '../widgets/map_filter_chips.dart';
import '../widgets/map_report_preview_card.dart';

/// Layar Peta (C — tab "Peta").
///
/// Menampilkan laporan warga di sekitar sebagai marker berwarna sesuai status,
/// dengan bar pencarian mengambang, baris chip filter kategori, dan kartu
/// pratinjau laporan terpilih di bawah. Tap marker memilih laporannya.
///
/// TAHAN-BANTING: GoogleMap tetap dirender walau API key Maps belum dipasang
/// (tile kosong, tidak crash) — mengikuti pola ReportMiniMap & Step 3. Peta ini
/// interaktif (marker bisa di-tap, peta bisa digeser) sehingga lite mode TIDAK
/// dipakai agar tap marker tetap berfungsi. Data masih dummy
/// ([NearbyReport.dummyList]) sesuai cakupan branch citizen.
///
/// CATATAN: tidak memuat bottom navigation sendiri — itu disediakan parent
/// [CitizenMainNavigation].
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Pusat awal: Sidoarjo, selaras layar Watch Zone & Beranda.
  static const LatLng _initialCenter = LatLng(-7.4478, 112.7183);

  static const List<String> _categories = [
    'Semua',
    'Jalan',
    'Lampu',
    'Sampah',
    'Drainase',
  ];

  // Hanya laporan yang punya koordinat yang bisa menjadi marker di peta.
  final List<NearbyReport> _reports = NearbyReport.dummyList
      .where((r) => r.location != null)
      .toList(growable: false);

  GoogleMapController? _mapController;
  int _selectedCategory = 0;

  // Laporan yang kartunya sedang tampil. Default laporan pertama agar kartu
  // pratinjau langsung terlihat saat layar dibuka (selaras desain Figma).
  late NearbyReport? _selectedReport = _reports.isNotEmpty ? _reports.first : null;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Petakan warna status laporan ke hue marker bawaan Google Maps.
  double _hueFor(Color statusColor) {
    if (statusColor == AppColors.error) return BitmapDescriptor.hueRed;
    if (statusColor == AppColors.success) return BitmapDescriptor.hueGreen;
    return BitmapDescriptor.hueOrange; // accent / "Diproses"
  }

  Set<Marker> _buildMarkers() {
    return _reports.map((report) {
      return Marker(
        markerId: MarkerId(report.title),
        position: report.location!,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(report.statusColor)),
        infoWindow: InfoWindow(title: report.title, snippet: report.address),
        onTap: () => setState(() => _selectedReport = report),
      );
    }).toSet();
  }

  /// Geser kamera ke laporan terpilih lalu tampilkan kartunya.
  void _focusReport(NearbyReport report) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(report.location!));
    setState(() => _selectedReport = report);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          // Overlay atas: bar pencarian + chip filter.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _SearchBar(),
                  ),
                  const SizedBox(height: 12),
                  MapFilterChips(
                    categories: _categories,
                    selectedIndex: _selectedCategory,
                    onSelected: (i) => setState(() => _selectedCategory = i),
                  ),
                ],
              ),
            ),
          ),
          // Kartu pratinjau laporan terpilih, mengambang di atas bottom nav.
          if (_selectedReport != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: MapReportPreviewCard(
                  report: _selectedReport!,
                  onTap: () => _focusReport(_selectedReport!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Peta laporan. Tetap dirender walau API key belum ada (tahan-banting).
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition:
          const CameraPosition(target: _initialCenter, zoom: 14),
      onMapCreated: (c) => _mapController = c,
      markers: _buildMarkers(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      // Tap kosong pada peta menutup kartu pratinjau.
      onTap: (_) => setState(() => _selectedReport = null),
    );
  }
}

/// Bar pencarian mengambang (dekoratif — pencarian alamat belum dibangun di
/// branch ini).
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Cari lokasi atau alamat',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, size: 20, color: AppColors.textPrimary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cari lokasi atau alamat...',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
