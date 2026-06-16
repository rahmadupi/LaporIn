import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reports/domain/repositories/reports_repository.dart';
import '../../../reports/presentation/screens/report_detail_screen.dart';
import '../models/nearby_report.dart';
import '../providers/nearby_reports_notifier.dart';
import '../widgets/map_filter_chips.dart';
import '../widgets/map_report_preview_card.dart';

/// Layar Peta (tab "Peta") — marker laporan REAL dari Firestore.
///
/// Menampilkan laporan publik terbaru sebagai marker berwarna sesuai status,
/// dengan chip filter kategori dan kartu pratinjau laporan terpilih. Tap marker
/// memilih laporannya; tap kartu membuka Detail. Tidak memuat bottom navigation
/// sendiri (disediakan parent [CitizenMainNavigation]).
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          NearbyReportsNotifier(repository: ctx.read<ReportsRepository>()),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  // Pusat awal: Sidoarjo (dipakai sebelum data/marker masuk).
  static const LatLng _initialCenter = LatLng(-7.4478, 112.7183);

  // Label chip -> slug kategori (null = "Semua").
  static const List<(String, String?)> _filters = [
    ('Semua', null),
    ('Jalan', 'road_damage'),
    ('Lampu', 'street_light'),
    ('Sampah', 'trash'),
    ('Drainase', 'drainage'),
  ];

  GoogleMapController? _mapController;
  int _selectedCategory = 0;
  String? _selectedReportId;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Petakan warna status laporan ke hue marker bawaan Google Maps.
  double _hueFor(Color statusColor) {
    if (statusColor == AppColors.error) return BitmapDescriptor.hueRed;
    if (statusColor == AppColors.success) return BitmapDescriptor.hueGreen;
    if (statusColor == AppColors.primary) return BitmapDescriptor.hueAzure;
    return BitmapDescriptor.hueOrange;
  }

  List<NearbyReport> _filtered(List<NearbyReport> all) {
    final slug = _filters[_selectedCategory].$2;
    final withLocation = all.where((r) => r.location != null);
    if (slug == null) return withLocation.toList();
    return withLocation.where((r) => r.categorySlug == slug).toList();
  }

  Set<Marker> _buildMarkers(List<NearbyReport> reports) {
    return reports.map((report) {
      return Marker(
        markerId: MarkerId(report.reportId),
        position: report.location!,
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(report.statusColor)),
        infoWindow: InfoWindow(title: report.title, snippet: report.address),
        onTap: () => setState(() => _selectedReportId = report.reportId),
      );
    }).toSet();
  }

  void _openDetail(String reportId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(reportId: reportId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NearbyReportsNotifier>();
    final reports = _filtered(notifier.items);

    // Laporan terpilih (bila masih ada setelah filter berubah).
    final selected = reports.where((r) => r.reportId == _selectedReportId);
    final selectedReport = selected.isNotEmpty
        ? selected.first
        : (reports.isNotEmpty ? reports.first : null);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(reports)),
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
                    child: _InfoBar(),
                  ),
                  const SizedBox(height: 12),
                  MapFilterChips(
                    categories: _filters.map((f) => f.$1).toList(),
                    selectedIndex: _selectedCategory,
                    onSelected: (i) => setState(() {
                      _selectedCategory = i;
                      _selectedReportId = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
          // Status kosong/loading di tengah bila belum ada marker.
          if (notifier.status == NearbyStatus.loading)
            const Center(child: CircularProgressIndicator())
          else if (reports.isEmpty)
            const _NoReportsHint(),
          if (selectedReport != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: MapReportPreviewCard(
                  report: selectedReport,
                  onTap: () => _openDetail(selectedReport.reportId),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(List<NearbyReport> reports) {
    return GoogleMap(
      initialCameraPosition:
          const CameraPosition(target: _initialCenter, zoom: 13),
      onMapCreated: (c) => _mapController = c,
      markers: _buildMarkers(reports),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onTap: (_) => setState(() => _selectedReportId = null),
    );
  }
}

/// Bar info ringkas di atas peta (menggantikan search bar dekoratif).
class _InfoBar extends StatelessWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(Icons.place_outlined, size: 20, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Laporan warga di sekitar Anda',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petunjuk saat belum ada laporan untuk filter terpilih.
class _NoReportsHint extends StatelessWidget {
  const _NoReportsHint();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Text(
          'Belum ada laporan pada kategori ini',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
