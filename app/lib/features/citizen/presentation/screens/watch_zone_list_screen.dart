import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../models/watch_zone.dart';
import '../widgets/watch_zone_card_widget.dart';
import 'watch_zone_screen.dart';

/// Daftar Watch Zone (C — tab "Watch Zones").
///
/// Menampilkan zona yang dipantau warga sebagai daftar kartu, dengan tombol "+"
/// di AppBar dan tombol "Tambah Watch Zone" di bawah. Membuat/mengedit zona
/// dibuka lewat [WatchZoneScreen] (layar atur peta). Data zona masih lokal/dummy
/// ([WatchZone.dummyList]) sesuai cakupan branch citizen.
///
/// CATATAN: tidak memuat bottom navigation sendiri — itu disediakan parent
/// [CitizenMainNavigation].
class WatchZoneListScreen extends StatelessWidget {
  const WatchZoneListScreen({super.key});

  /// Buka layar Atur Watch Zone untuk membuat/mengedit zona. [onClose] memetik
  /// pop agar tombol kembali/tutup di layar atur mengembalikan ke daftar ini.
  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatchZoneScreen(
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zones = WatchZone.dummyList;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Watch Zones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AddIconButton(onTap: () => _openEditor(context)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: zones.isEmpty
            ? _EmptyState(onAdd: () => _openEditor(context))
            : _ZoneList(zones: zones, onOpen: () => _openEditor(context)),
      ),
    );
  }
}

/// Tombol "+" bulat di AppBar (lingkaran biru sangat muda + ikon primer).
class _AddIconButton extends StatelessWidget {
  const _AddIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah Watch Zone',
      child: Material(
        color: AppColors.primarySoft,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.add, size: 22, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Daftar kartu zona + tombol "Tambah Watch Zone" di bawah.
class _ZoneList extends StatelessWidget {
  const _ZoneList({required this.zones, required this.onOpen});

  final List<WatchZone> zones;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${zones.length} zona dipantau',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Satu kartu per zona; tap kartu membuka layar atur untuk edit.
          ...zones.map(
            (zone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WatchZoneCardWidget(
                zoneName: zone.name,
                activityText: zone.activityText,
                hasActivity: zone.hasActivity,
                onTap: onOpen,
              ),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(label: 'Tambah Watch Zone', onPressed: onOpen),
        ],
      ),
    );
  }
}

/// Tampilan kosong saat warga belum punya zona.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_red_eye_outlined,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada Watch Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pantau area favoritmu dan dapat notifikasi saat ada laporan baru '
              'di sekitarnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Tambah Watch Zone', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
