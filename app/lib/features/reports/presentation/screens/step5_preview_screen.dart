import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/report_form_notifier.dart';
import '../widgets/report_step_scaffold.dart';

/// Lapor Step 5 — Preview & Submit.
///
/// Menampilkan ringkasan SEMUA data yang terkumpul di notifier lalu mengirim.
/// Tombol "Kirim Laporan" memicu upload Storage + write Firestore via
/// [ReportFormNotifier.submit]. Bila sukses, memanggil [onSubmitted] agar flow
/// pindah ke Success Screen.
class Step5PreviewScreen extends StatelessWidget {
  const Step5PreviewScreen({
    super.key,
    required this.onBack,
    required this.onSubmitted,
  });

  final VoidCallback onBack;
  final VoidCallback onSubmitted;

  Future<void> _submit(BuildContext context) async {
    final notifier = context.read<ReportFormNotifier>();
    // UID user dipakai notifier untuk menentukan reporterId (atau di-hash bila
    // anonim). Diambil di sini karena AuthProvider hidup di level app.
    final uid = context.read<AuthProvider>().user?.uid;

    final success = await notifier.submit(authUid: uid);
    if (!context.mounted) return;

    if (success) {
      onSubmitted();
    } else {
      SnackbarHelper.showError(
          context, notifier.errorMessage ?? 'Gagal mengirim laporan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportFormNotifier>();
    final photo = notifier.photo;

    return ReportStepScaffold(
      currentStep: 5,
      title: 'Preview Laporan',
      subtitle: 'Periksa kembali sebelum mengirim.',
      primaryLabel: 'Kirim Laporan',
      isLoading: notifier.isSubmitting,
      onBack: onBack,
      // Saat sedang mengirim, tombol di-disable (null) agar tak double-submit.
      onPrimary: notifier.isSubmitting ? null : () => _submit(context),
      child: ListView(
        children: [
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(photo, height: 180,
                  width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          _PreviewRow(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: notifier.category?.label ?? '-',
          ),
          _PreviewRow(
            icon: Icons.location_on_outlined,
            label: 'Lokasi',
            value: notifier.address.isNotEmpty ? notifier.address : '-',
          ),
          _PreviewRow(
            icon: Icons.priority_high,
            label: 'Keparahan',
            value: notifier.severity.label,
            valueColor: notifier.severity.color,
          ),
          _PreviewRow(
            icon: Icons.notes_outlined,
            label: 'Deskripsi',
            value: notifier.description.trim().isNotEmpty
                ? notifier.description.trim()
                : '(tidak diisi)',
          ),
          _PreviewRow(
            icon: notifier.isAnonymous
                ? Icons.visibility_off_outlined
                : Icons.person_outline,
            label: 'Pelapor',
            value: notifier.isAnonymous ? 'Anonim' : 'Akun Saya',
          ),
        ],
      ),
    );
  }
}

/// Satu baris ringkasan (ikon + label + nilai) di preview.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
