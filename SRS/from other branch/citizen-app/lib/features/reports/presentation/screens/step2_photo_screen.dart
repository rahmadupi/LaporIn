import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/report_form_notifier.dart';
import '../widgets/report_step_scaffold.dart';

/// Lapor Step 2 — Ambil Foto (image_picker).
///
/// Memakai StatefulWidget karena memegang [ImagePicker] dan menjalankan operasi
/// async (membuka kamera/galeri) yang perlu guard `mounted`.
class Step2PhotoScreen extends StatefulWidget {
  const Step2PhotoScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step2PhotoScreen> createState() => _Step2PhotoScreenState();
}

class _Step2PhotoScreenState extends State<Step2PhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  /// Ambil gambar dari [source] lalu simpan File-nya ke notifier.
  ///
  /// Foto dikompres lewat parameter image_picker (maxWidth 1280, kualitas 70)
  /// untuk memenuhi NFR-1 (upload < 10 dtk, ~200KB) sejak di sumbernya.
  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (picked == null) return; // User membatalkan pemilihan.
      if (!mounted) return;
      context.read<ReportFormNotifier>().setPhoto(File(picked.path));
    } catch (_) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, 'Tidak dapat mengakses kamera/galeri.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportFormNotifier>();
    final photo = notifier.photo;

    return ReportStepScaffold(
      currentStep: 2,
      title: 'Ambil Foto',
      subtitle: 'Foto kerusakan membantu petugas memverifikasi laporan.',
      primaryLabel: 'Lanjut',
      onBack: widget.onBack,
      onPrimary: notifier.isStep2Valid ? widget.onNext : null,
      child: Column(
        children: [
          // Area preview: tampilkan foto bila ada, atau placeholder bila belum.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: photo == null
                  ? const _PhotoPlaceholder()
                  : Image.file(photo, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          // Dua pilihan sumber: kamera (utama) & galeri.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(photo == null ? 'Ambil Foto' : 'Foto Ulang'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Placeholder saat belum ada foto dipilih.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Belum ada foto',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
