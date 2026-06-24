import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Sticky bottom action bar di Detail: tombol "Edit" & "Hapus".
///
/// Hanya dirender oleh Detail saat status laporan masih `pending` (FR-2.4 &
/// FR-2.5). Widget ini sendiri tidak menyimpan aturan itu — ia hanya menampilkan
/// tombol & meneruskan aksi lewat callback agar tetap reusable.
class ReportDetailActionBar extends StatelessWidget {
  const ReportDetailActionBar({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.isProcessing = false,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Saat true (proses hapus berjalan), tombol dinonaktifkan agar tak dobel.
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        // Garis & bayangan tipis memisahkan bar dari konten yang ter-scroll.
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Edit: aksi sekunder -> outlined.
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isProcessing ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Hapus: aksi destruktif -> merah terisi.
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onDelete,
                icon: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
