import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/nearby_report.dart';
import '../widgets/hero_card_widget.dart';
import '../widgets/home_header.dart';
import '../widgets/report_card_widget.dart';
import '../widgets/stat_item_card.dart';
import '../widgets/watch_zone_card_widget.dart';

/// Citizen Home / Beranda (C1).
///
/// Screen ini hanya MERANGKAI komponen (header, hero card, statistik, list
/// laporan terdekat, watch zone) — tiap komponen kompleks sudah dipindah ke
/// folder widgets/. Tujuannya menjaga screen tetap mudah dibaca: alur layout
/// terlihat sekilas, detail visual ada di masing-masing widget.
///
/// Semua data masih DUMMY (sesuai cakupan branch). Tombol "Lapor" diberikan
/// dari parent (Main Navigation) lewat [onReportTap] agar hero card dan FAB
/// memicu aksi yang sama.
class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key, required this.onReportTap});

  /// Callback ketika user menekan "Buat Laporan" di hero card.
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    // read: nama user untuk sapaan; tidak perlu rebuild saat auth berubah.
    final user = context.read<AuthProvider>().user;
    // Ambil nama depan saja agar sapaan ringkas; fallback "Warga" bila kosong.
    final firstName = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim().split(' ').first
        : 'Warga';

    return Scaffold(
      // SafeArea + ListView agar konten bisa di-scroll dan aman dari notch.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            HomeHeader(
              greetingName: firstName,
              location: 'Sidoarjo, Jawa Timur',
              // Buka Riwayat Laporan (C7) lewat named route.
              onHistoryTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.citizenReports),
              // Buka Notification Center lewat named route.
              onNotificationTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.citizenNotifications),
            ),
            const SizedBox(height: 16),
            // Hero card meneruskan aksi ke FAB Lapor milik Main Navigation.
            HeroCardWidget(onReport: onReportTap),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Laporan Terdekat',
              actionLabel: 'Lihat Peta →',
            ),
            const SizedBox(height: 12),
            _buildNearbyList(),
            const SizedBox(height: 24),
            const Text(
              'Aktivitas Watch Zones Anda',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const WatchZoneCardWidget(
              zoneName: 'Perumahan Bumi Sidoarjo',
              activityText: '2 laporan baru hari ini',
            ),
          ],
        ),
      ),
    );
  }

  /// Baris tiga statistik ringkas (data dummy sesuai mockup).
  Widget _buildStatsRow() {
    return const Row(
      children: [
        Expanded(
          child: StatItemCard(
            value: '12',
            label: 'Laporan Aktif',
            valueColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatItemCard(
            value: '47',
            label: 'Selesai',
            valueColor: AppColors.success,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatItemCard(
            value: '3',
            label: 'Watch Zones',
            valueColor: AppColors.accent,
          ),
        ),
      ],
    );
  }

  /// Header section dengan judul kiri dan tautan aksi kanan (mis. "Lihat Peta").
  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  /// List horizontal kartu laporan terdekat; tinggi dibatasi agar bisa di-scroll
  /// ke samping di dalam ListView vertikal.
  Widget _buildNearbyList() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: NearbyReport.dummyList.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) =>
            ReportCardWidget(report: NearbyReport.dummyList[index]),
      ),
    );
  }
}
