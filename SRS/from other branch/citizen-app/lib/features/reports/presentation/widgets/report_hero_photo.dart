import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Hero photo di atas halaman Detail — carousel bila laporan punya >1 foto.
///
/// Dipisah menjadi StatefulWidget karena memegang indeks halaman aktif untuk
/// indikator titik. Menangani daftar kosong & error muat gambar dengan aman.
class ReportHeroPhoto extends StatefulWidget {
  const ReportHeroPhoto({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<ReportHeroPhoto> createState() => _ReportHeroPhotoState();
}

class _ReportHeroPhotoState extends State<ReportHeroPhoto> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = 240.0;

    // Tanpa foto: tampilkan placeholder agar layout tetap rapi.
    if (widget.photoUrls.isEmpty) {
      return Container(
        height: height,
        color: AppColors.scaffoldBackground,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 48, color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photoUrls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Image.network(
              widget.photoUrls[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.scaffoldBackground,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 48, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          // Indikator titik hanya muncul bila foto lebih dari satu.
          if (widget.photoUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photoUrls.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
