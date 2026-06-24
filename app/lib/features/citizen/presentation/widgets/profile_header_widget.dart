import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Header biru melengkung di layar Profil: avatar, nama, dan email.
///
/// Data identitas (nama & email) berasal dari user login. Statistik nyata
/// (jumlah laporan, selesai, watch zone) ditampilkan terpisah pada baris
/// statistik di bawah header ini, bukan sebagai badge statis.
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
        ],
      ),
    );
  }

  /// Avatar inisial nama.
  ///
  /// Memakai inisial nama (bukan NetworkImage) supaya tidak bergantung koneksi
  /// internet dan tidak perlu foto profil yang belum tersedia.
  Widget _buildAvatar() {
    final initials = _initialsOf(name);
    return CircleAvatar(
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
