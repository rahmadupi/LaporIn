import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Kerangka (chrome) yang sama untuk tiap layar Step 1–5.
///
/// Dipisah agar tiap file step hanya fokus pada KONTEN-nya, bukan mengulang
/// AppBar, indikator progres, dan tombol bawah. Konsistensi visual antar-step
/// pun terjaga otomatis dari satu tempat.
class ReportStepScaffold extends StatelessWidget {
  const ReportStepScaffold({
    super.key,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
    this.isLoading = false,
  });

  /// Nomor langkah 1..5 (untuk indikator progres).
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;

  final String primaryLabel;

  /// null = tombol disabled (mis. data wajib belum diisi).
  final VoidCallback? onPrimary;
  final VoidCallback onBack;
  final bool isLoading;

  static const int _totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Buat Laporan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Back diserahkan ke flow (mundur 1 step / keluar bila di step 1).
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indikator progres 5 segmen di paling atas konten.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _StepProgress(
                  currentStep: currentStep, totalSteps: _totalSteps),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Konten step mengisi sisa ruang & boleh scroll sendiri bila perlu.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
            // Tombol aksi utama selalu menempel di bawah.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: primaryLabel,
                onPressed: onPrimary,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indikator progres: 5 segmen horizontal + label "Langkah n dari 5".
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            // Segmen terisi biru bila step-nya sudah dilewati/aktif.
            final isDone = index < currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Langkah $currentStep dari $totalSteps',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
