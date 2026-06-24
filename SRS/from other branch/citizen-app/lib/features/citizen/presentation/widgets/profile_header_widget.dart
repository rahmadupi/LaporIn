import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Header biru melengkung di layar Profil: avatar, nama, email, dan dua chip
/// badge penghargaan.
///
/// Dipecah dari screen karena cukup padat (avatar bertumpuk badge kamera,
/// gradient, chip). Data identitas dilempar lewat parameter agar bisa diisi
/// dari user login (nama & email) sementara badge masih dummy.
class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    super.key,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          // Dua chip badge berjajar; dibungkus Wrap agar aman bila teks panjang.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _BadgeChip(icon: Icons.emoji_events, label: 'Pejuang Jalan'),
              _BadgeChip(icon: Icons.star, label: 'Pelapor Aktif'),
            ],
          ),
        ],
      ),
    );
  }

  /// Avatar inisial + badge kamera kecil (placeholder ganti foto profil).
  ///
  /// Memakai inisial nama, bukan NetworkImage, supaya tidak bergantung koneksi
  /// internet saat tahap UI dummy ini.
  Widget _buildAvatar() {
    final initials = _initialsOf(name);
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        // Badge kamera menandakan foto bisa diganti (fitur menyusul).
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Ambil maksimal dua huruf awal dari nama untuk inisial avatar.
  String _initialsOf(String value) {
    final parts =
        value.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

/// Chip badge penghargaan kecil (ikon + label) berlatar putih transparan.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
