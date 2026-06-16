import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/geo_distance.dart';
import '../../../reports/domain/entities/report.dart';

/// View model satu kartu "Laporan Terdekat" (Beranda & Peta).
///
/// Bukan data dummy: dibangun dari entitas [Report] asli Firestore lewat
/// [NearbyReport.fromReport]. Memisahkan view model dari entitas domain menjaga
/// widget kartu tetap presentational dan tidak bergantung pada tipe Firestore.
class NearbyReport {
  const NearbyReport({
    required this.reportId,
    required this.categorySlug,
    required this.title,
    required this.address,
    required this.distance,
    required this.timeAgo,
    required this.statusLabel,
    required this.statusColor,
    required this.imageColor,
    required this.imageIcon,
    this.location,
  });

  final String reportId;

  /// Slug kategori (untuk filter chip di Peta).
  final String categorySlug;
  final String title;
  final String address;
  final String distance;
  final String timeAgo;

  /// Koordinat di peta (selalu ada untuk laporan asli).
  final LatLng? location;

  /// Label & warna badge status (mengikuti ReportStatus).
  final String statusLabel;
  final Color statusColor;

  /// Blok warna + ikon mewakili kategori (thumbnail ringan tanpa memuat foto).
  final Color imageColor;
  final IconData imageIcon;

  /// Bangun dari [report]. Bila [originLat]/[originLng] tersedia (lokasi GPS
  /// pengguna), jarak dihitung; jika tidak, tampilkan placeholder netral.
  factory NearbyReport.fromReport(
    Report report, {
    double? originLat,
    double? originLng,
  }) {
    final distanceLabel = (originLat != null && originLng != null)
        ? GeoDistance.format(
            GeoDistance.meters(
              originLat,
              originLng,
              report.latitude,
              report.longitude,
            ),
          )
        : 'Sekitar';

    return NearbyReport(
      reportId: report.reportId,
      categorySlug: report.category.slug,
      title: report.category.label,
      address: report.address.isNotEmpty ? report.address : 'Lokasi laporan',
      distance: distanceLabel,
      timeAgo: DateFormatter.relative(report.createdAt),
      statusLabel: report.status.label,
      statusColor: report.status.color,
      imageColor: _categoryColor(report),
      imageIcon: report.category.icon,
      location: LatLng(report.latitude, report.longitude),
    );
  }

  /// Warna thumbnail berdasarkan keparahan agar konsisten lintas kartu.
  static Color _categoryColor(Report report) {
    switch (report.severity.slug) {
      case 'high':
        return const Color(0xFF5B6472);
      case 'low':
        return const Color(0xFF12B76A);
      default:
        return AppColors.primary;
    }
  }
}
