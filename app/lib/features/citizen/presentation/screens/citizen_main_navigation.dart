import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import 'citizen_home_screen.dart';
import 'citizen_profile_screen.dart';
import 'placeholder_tab_screen.dart';

/// Main Navigation Wrapper untuk area Citizen.
///
/// Inilah "cangkang" yang dituju setelah login sebagai warga. Bertugas:
///   1. Menahan state tab aktif ([_currentIndex]) -> StatefulWidget.
///   2. Menyimpan keempat halaman tab di [IndexedStack] supaya state tiap tab
///      (posisi scroll, dll) TIDAK hilang saat berpindah tab.
///   3. Menyusun BottomAppBar custom dengan takik (notch) + FAB "Lapor" di
///      tengah yang menonjol — mengikuti desain mockup Beranda.
///
/// Catatan desain: mockup menyebut 5 menu (Beranda, Peta, Lapor, Watch Zones,
/// Profil), tetapi "Lapor" bukan tab biasa melainkan FAB. Jadi IndexedStack
/// hanya berisi 4 halaman; FAB memicu aksi tersendiri.
class CitizenMainNavigation extends StatefulWidget {
  const CitizenMainNavigation({super.key});

  @override
  State<CitizenMainNavigation> createState() => _CitizenMainNavigationState();
}

class _CitizenMainNavigationState extends State<CitizenMainNavigation> {
  // Tab yang sedang ditampilkan. 0=Beranda, 1=Peta, 2=Watch Zones, 3=Profil.
  int _currentIndex = 0;

  // Daftar halaman tab. 'late' karena Home perlu callback _onReportTap yang
  // baru tersedia setelah instance state dibuat.
  late final List<Widget> _pages = [
    CitizenHomeScreen(onReportTap: _onReportTap),
    const PlaceholderTabScreen(title: 'Peta', icon: Icons.map_outlined),
    const PlaceholderTabScreen(
        title: 'Watch Zones', icon: Icons.remove_red_eye_outlined),
    const CitizenProfileScreen(),
  ];

  /// Pindah tab; setState memicu IndexedStack menampilkan halaman lain.
  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  /// Aksi tombol "Lapor": buka alur multi-step Buat Laporan.
  ///
  /// Dipanggil oleh FAB tengah maupun tombol "Buat Laporan" di hero card
  /// Beranda — keduanya berbagi satu entry-point pelaporan.
  void _onReportTap() {
    Navigator.of(context).pushNamed(AppRoutes.createReport);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Agar body terlihat di balik takik BottomAppBar.
      // IndexedStack mempertahankan tiap tab tetap hidup di memori.
      body: IndexedStack(index: _currentIndex, children: _pages),

      // FAB "Lapor" di tengah, didock ke BottomAppBar lewat location di bawah.
      floatingActionButton: FloatingActionButton(
        onPressed: _onReportTap,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BottomAppBar dengan takik melingkar tempat FAB "duduk".
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          // Dua item kiri & dua item kanan, menyisakan ruang takik di tengah.
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Beranda',
              isActive: _currentIndex == 0,
              onTap: () => _onTabSelected(0),
            ),
            _NavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Peta',
              isActive: _currentIndex == 1,
              onTap: () => _onTabSelected(1),
            ),
            // Ruang kosong selebar FAB agar dua item kanan tidak menempel takik.
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.remove_red_eye_outlined,
              activeIcon: Icons.remove_red_eye,
              label: 'Watch Zones',
              isActive: _currentIndex == 2,
              onTap: () => _onTabSelected(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profil',
              isActive: _currentIndex == 3,
              onTap: () => _onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu item navigasi (ikon + label) di BottomAppBar.
///
/// Dibuat privat di file ini karena hanya relevan untuk navigation wrapper.
/// Menyorot warna primer saat aktif agar tab terpilih jelas terbaca.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      // InkWell memberi area tap penuh setinggi bar (touch target >44px).
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
