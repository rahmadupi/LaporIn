import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Model data DUMMY untuk satu kartu di daftar "Laporan Terdekat".
///
/// Dibuat sebagai model tersendiri (bukan sekadar Map) agar widget kartu
/// punya kontrak data yang jelas dan type-safe. Pada tahap ini semua nilainya
/// statis; ketika fitur Reports asli dibangun, model ini cukup diganti dengan
/// entitas Firestore tanpa mengubah widget yang mengonsumsinya.
class NearbyReport {
  const NearbyReport({
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

  final String title;
  final String address;
  final String distance;
  final String timeAgo;

  /// Koordinat di peta (opsional). Dipakai layar Peta untuk menempatkan marker;
  /// di Beranda (list horizontal) field ini tidak terpakai sehingga dibuat
  /// nullable agar model tetap satu sumber untuk kedua layar.
  final LatLng? location;

  /// Label & warna badge status (mis. "Diproses" oranye, "Menunggu" merah).
  final String statusLabel;
  final Color statusColor;

  /// Karena belum ada foto asli dari Storage, kartu memakai blok warna +
  /// ikon sebagai placeholder gambar kerusakan.
  final Color imageColor;
  final IconData imageIcon;

  /// Data contoh untuk mengisi list horizontal di Beranda.
  static const List<NearbyReport> dummyList = [
    NearbyReport(
      title: 'Jalan Berlubang Parah',
      address: 'Jl. Diponegoro, Sidoarjo',
      distance: '0.5 km',
      timeAgo: '2 jam lalu',
      statusLabel: 'Diproses',
      statusColor: AppColors.accent,
      imageColor: Color(0xFF5B6472),
      imageIcon: Icons.dangerous_outlined,
      location: LatLng(-7.4478, 112.7183),
    ),
    NearbyReport(
      title: 'Lampu Jalan Mati',
      address: 'Perum. Taman Pinang, Sidoarjo',
      distance: '1.2 km',
      timeAgo: '5 jam lalu',
      statusLabel: 'Menunggu',
      statusColor: AppColors.error,
      imageColor: Color(0xFF3D6FBF),
      imageIcon: Icons.lightbulb_outline,
      location: LatLng(-7.4521, 112.7106),
    ),
    NearbyReport(
      title: 'Drainase Tersumbat',
      address: 'Jl. Pahlawan, Sidoarjo',
      distance: '2.0 km',
      timeAgo: '1 hari lalu',
      statusLabel: 'Selesai',
      statusColor: AppColors.success,
      imageColor: Color(0xFF12B76A),
      imageIcon: Icons.water_drop_outlined,
      location: LatLng(-7.4432, 112.7259),
    ),
  ];
}
