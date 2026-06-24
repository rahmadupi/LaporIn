import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Satu baris menu di layar Profil (kartu putih: ikon bulat, judul, chevron).
///
/// Dibuat reusable karena daftar pengaturan profil berisi banyak item yang
/// bentuknya identik. Mode [isDestructive] dipakai untuk item "Keluar" agar
/// tampil merah tanpa perlu widget terpisah.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// True untuk aksi berbahaya (Keluar): warna merah & tanpa chevron.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    // Warna disesuaikan: merah untuk destruktif, biru untuk menu biasa.
    final Color accentColor =
        isDestructive ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      // Material+InkWell memberi efek ripple saat ditekan, tetap sudut membulat.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Item destruktif tidak butuh chevron (bukan navigasi lanjutan).
                if (!isDestructive)
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
