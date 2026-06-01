import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Success Screen — konfirmasi laporan terkirim + nomor tiket.
///
/// Layar ini SENGAJA berdiri sendiri (tidak butuh ReportFormNotifier): ia hanya
/// menerima [ticketId] sebagai argumen. Karena itu, setelah submit sukses kita
/// bisa pushReplacement ke sini dan membiarkan notifier flow di-dispose.
class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, required this.ticketId});

  /// Nomor tiket (reportId) hasil submit, mis. "LPR-2026-0001234".
  final String ticketId;

  /// Kembali ke Beranda sambil membuang seluruh stack flow lapor, agar tombol
  /// back tidak membawa user kembali ke halaman preview.
  void _backToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.citizenHome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ikon centang dalam lingkaran hijau sebagai penanda sukses.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Terima kasih telah berkontribusi untuk kotamu. '
                'Laporanmu sedang menunggu verifikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              // Kartu nomor tiket — referensi warga untuk melacak laporan.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Nomor Tiket',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      ticketId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Estimasi respon: 1x24 jam',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Kembali ke Beranda',
                onPressed: () => _backToHome(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
