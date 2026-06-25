import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/dispatches/data/repositories/dispatch_repository.dart';

/// Tombol "Saya Ingin Menangani Laporan Ini" (OFC-003) yang menampilkan
/// state berbeda bergantung pada apakah officer sudah pernah
/// self-request laporan ini.
///
/// State yang dikenali dari [mySelfRequestedReportIdsProvider]:
/// - `null` → belum login, sembunyikan tombol
/// - `Set` kosong → tampilkan tombol "Saya Ingin Menangani" (aktif)
/// - `Set` berisi `reportId` → tampilkan tombol disabled "Sudah Diajukan"
class SelfRequestButton extends ConsumerStatefulWidget {
  const SelfRequestButton({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<SelfRequestButton> createState() => _SelfRequestButtonState();
}

class _SelfRequestButtonState extends ConsumerState<SelfRequestButton> {
  bool _isSubmitting = false;

  Future<void> _onTap() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(dispatchRepositoryProvider)
          .submitSelfRequest(
            reportId: widget.reportId,
            officerId: user.uid,
            officerName: user.fullName,
          );
      // Invalidate supaya tombol langsung berubah ke "Sudah Diajukan".
      ref.invalidate(mySelfRequestedReportIdsProvider(user.uid));
      ref.invalidate(mySelfRequestsStreamProvider(user.uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajuan terkirim. Menunggu persetujuan Admin.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ajuan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();
    final alreadyRequested = ref
        .watch(mySelfRequestedReportIdsProvider(user.uid))
        .contains(widget.reportId);

    if (alreadyRequested) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Sudah Diajukan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _onTap,
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.front_hand),
        label: const Text('Saya Ingin Menangani Laporan Ini'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
