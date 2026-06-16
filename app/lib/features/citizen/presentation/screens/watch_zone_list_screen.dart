import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/watch_zone.dart';
import '../../domain/repositories/watch_zone_repository.dart';
import '../providers/watch_zone_notifier.dart';
import '../widgets/radius_slider.dart';
import '../widgets/watch_zone_card_widget.dart';
import 'watch_zone_screen.dart';

/// Daftar Watch Zone (tab "Watch Zones") — data REAL dari Firestore.
///
/// Menyediakan [WatchZoneNotifier] (stream zona milik user). Mendukung Create
/// (tombol +), Read (daftar), Update (tap kartu -> editor), dan soft Delete
/// (geser kartu). Tidak memuat bottom navigation sendiri (disediakan parent).
class WatchZoneListScreen extends StatelessWidget {
  const WatchZoneListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return ChangeNotifierProvider(
      create: (ctx) => WatchZoneNotifier(
        repository: ctx.read<WatchZoneRepository>(),
        userId: uid,
      ),
      child: Scaffold(
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
            Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _AddIconButton(onTap: () => _openEditor(ctx)),
              ),
            ),
          ],
        ),
        body: const SafeArea(top: false, child: _ZoneListBody()),
      ),
    );
  }

  /// Buka editor. [zone] != null = mode edit. Notifier turun lewat Provider.of
  /// agar tetap hidup saat editor di-push (editor menulis, stream menyegarkan).
  static void _openEditor(BuildContext context, {WatchZone? zone}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatchZoneScreen(
          existing: zone,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _ZoneListBody extends StatelessWidget {
  const _ZoneListBody();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<WatchZoneNotifier>();

    switch (notifier.status) {
      case WatchZoneStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case WatchZoneStatus.error:
        return _EmptyState(
          title: 'Gagal memuat',
          subtitle: notifier.error ?? 'Coba lagi nanti.',
          onAdd: () => WatchZoneListScreen._openEditor(context),
        );
      case WatchZoneStatus.loaded:
        if (notifier.isEmpty) {
          return _EmptyState(
            title: 'Belum ada Watch Zone',
            subtitle:
                'Pantau area favoritmu dan lihat laporan baru di sekitarnya.',
            onAdd: () => WatchZoneListScreen._openEditor(context),
          );
        }
        return _ZoneList(zones: notifier.zones, notifier: notifier);
    }
  }
}

/// Tombol "+" bulat di AppBar.
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
  const _ZoneList({required this.zones, required this.notifier});

  final List<WatchZone> zones;
  final WatchZoneNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${zones.length} zona dipantau',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...zones.map(
            (zone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(zone.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => notifier.delete(zone.id),
                child: WatchZoneCardWidget(
                  zoneName: zone.name,
                  activityText: _subtitle(zone),
                  hasActivity: false,
                  onTap: () =>
                      WatchZoneListScreen._openEditor(context, zone: zone),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Tambah Watch Zone',
            onPressed: () => WatchZoneListScreen._openEditor(context),
          ),
        ],
      ),
    );
  }

  /// Subtitle faktual (bukan dummy): radius + alamat pusat zona.
  String _subtitle(WatchZone zone) {
    final radius = 'Radius ${RadiusSlider.formatRadius(zone.radius)}';
    if (zone.address.isEmpty) return radius;
    return '$radius • ${zone.address}';
  }
}

/// Tampilan kosong / error.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Tambah Watch Zone', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
