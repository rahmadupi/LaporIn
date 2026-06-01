import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tampilan Before/After untuk laporan yang sudah `resolved`.
///
/// Menyandingkan foto sebelum & sesudah perbaikan. URL kedua foto bisa null
/// (jika flow penyelesaian Anggota C belum men-denormalisasi-nya), sehingga
/// tiap sisi punya placeholder agar tidak crash / kosong total.
class BeforeAfterView extends StatelessWidget {
  const BeforeAfterView({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  final String? beforeUrl;
  final String? afterUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PhotoColumn(label: 'Sebelum', url: beforeUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PhotoColumn(label: 'Sesudah', url: afterUrl),
        ),
      ],
    );
  }
}

class _PhotoColumn extends StatelessWidget {
  const _PhotoColumn({required this.label, required this.url});

  final String label;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: url == null
                ? const _EmptyPhoto()
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _EmptyPhoto(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
