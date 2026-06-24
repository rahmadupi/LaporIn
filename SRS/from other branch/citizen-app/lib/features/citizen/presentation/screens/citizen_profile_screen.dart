import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/stat_item_card.dart';

/// Citizen Profile / Profil Saya (C9).
///
/// Merangkai header biru, baris statistik, dan daftar menu pengaturan. Sebagian
/// besar UI memakai data dummy; SATU-SATUNYA logika nyata di sini adalah
/// Logout, yang memanggil AuthProvider.signOut() (FR-1.4).
class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Nama & email diambil dari user login; fallback dummy bila kosong agar
    // tampilan tetap utuh saat data belum lengkap.
    final user = context.read<AuthProvider>().user;
    final name = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : 'Budi Santoso';
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email.trim()
        : 'budi.s@email.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Layar ini adalah tab root di Main Navigation, jadi tidak ada yang
        // perlu di-pop -> back arrow sengaja dimatikan (beda dari mockup yang
        // menggambarkannya sebagai halaman berdiri sendiri).
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ProfileHeaderWidget(name: name, email: email),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          // Daftar menu pengaturan (semua placeholder kecuali Keluar).
          ProfileMenuTile(
            icon: Icons.notifications_none,
            title: 'Pengaturan Notifikasi',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.shield_outlined,
            title: 'Privasi & Anonimitas',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.language,
            title: 'Bahasa',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.help_outline,
            title: 'Bantuan & FAQ',
            onTap: () {},
          ),
          ProfileMenuTile(
            icon: Icons.info_outline,
            title: 'Tentang LaporIn',
            onTap: () {},
          ),
          const SizedBox(height: 4),
          // Tombol Logout NYATA: warna merah, memutus session.
          ProfileMenuTile(
            icon: Icons.logout,
            title: 'Keluar',
            isDestructive: true,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  /// Baris statistik profil (data dummy: total laporan, validasi, watch zones).
  Widget _buildStatsRow() {
    return const Row(
      children: [
        Expanded(
          child: StatItemCard(
            value: '24',
            label: 'Total Laporan',
            valueColor: AppColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatItemCard(
            value: '92%',
            label: 'Tingkat Validasi',
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

  /// Konfirmasi dulu, lalu jalankan logout sungguhan.
  ///
  /// Alur: tampilkan dialog -> jika user yakin -> AuthProvider.signOut()
  /// membersihkan session Firebase & state -> reset stack navigasi ke Login
  /// sehingga tombol back tidak bisa kembali ke area citizen.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // signOut() mengubah AuthStatus -> unauthenticated di provider.
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;

    // pushNamedAndRemoveUntil membuang seluruh history agar user benar-benar
    // keluar dari area aplikasi citizen, bukan sekadar menumpuk Login.
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }
}
