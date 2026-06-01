import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/repositories/reports_repository.dart';
import '../providers/rating_notifier.dart';

/// Menampilkan RatingBottomSheet (Flow 5) dan mengembalikan true bila rating
/// berhasil dikirim, sehingga pemanggil bisa menampilkan umpan balik.
///
/// Pembungkus fungsi ini menyuntikkan [RatingNotifier] yang umurnya hanya
/// selama sheet terbuka (transient state bintang & komentar).
Future<bool> showRatingBottomSheet(
  BuildContext context, {
  required String reportId,
  required String reporterId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider(
      create: (_) => RatingNotifier(context.read<ReportsRepository>()),
      child: _RatingSheetContent(reportId: reportId, reporterId: reporterId),
    ),
  );
  return result ?? false;
}

class _RatingSheetContent extends StatefulWidget {
  const _RatingSheetContent({required this.reportId, required this.reporterId});

  final String reportId;
  final String reporterId;

  @override
  State<_RatingSheetContent> createState() => _RatingSheetContentState();
}

class _RatingSheetContentState extends State<_RatingSheetContent> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = context.read<RatingNotifier>();
    final success = await notifier.submit(
      reportId: widget.reportId,
      reporterId: widget.reporterId,
      comment: _commentController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true); // Tutup sheet, kabari pemanggil.
    } else {
      SnackbarHelper.showError(
          context, notifier.errorMessage ?? 'Gagal mengirim rating.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch: rebuild saat bintang dipilih / status submit berubah.
    final notifier = context.watch<RatingNotifier>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Beri Rating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seberapa puas Anda dengan penyelesaian laporan ini?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Deretan bintang interaktif 1-5.
          _StarRow(
            stars: notifier.stars,
            onSelected: notifier.setStars,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Tulis komentar (opsional)...',
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Kirim Rating',
            isLoading: notifier.isSubmitting,
            // Disabled sampai minimal 1 bintang dipilih (canSubmit).
            onPressed: notifier.canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}

/// Lima bintang yang bisa diketuk; bintang <= pilihan tampil terisi.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.onSelected});

  final int stars;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1; // Bintang ke-1..5.
        final isFilled = value <= stars;
        return IconButton(
          onPressed: () => onSelected(value),
          iconSize: 40,
          icon: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isFilled ? AppColors.accent : AppColors.border,
          ),
        );
      }),
    );
  }
}
