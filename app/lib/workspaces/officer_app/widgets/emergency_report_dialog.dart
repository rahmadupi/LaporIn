import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

/// Dialog "Laporan Darurat" (OFC-012) — muncul ketika officer tap FAB
/// di Officer Home. Auto-capture GPS via Geolocator, submit membuat
/// dokumen baru di `/reports/{id}` dengan `status: "pending"`, sehingga
/// langsung muncul di admin report list.
///
/// Pola (FAB → dialog → submit) mengikuti
/// `SRS/officer/feature/officer_home.md` §3 (FAB) + §5 Scenario 3.
class EmergencyReportDialog extends ConsumerStatefulWidget {
  const EmergencyReportDialog({super.key});

  /// Helper untuk menampilkan dialog dari parent dan mengembalikan
  /// `true` bila submit berhasil, `false` jika dibatalkan / gagal.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const EmergencyReportDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<EmergencyReportDialog> createState() =>
      _EmergencyReportDialogState();
}

class _EmergencyReportDialogState extends ConsumerState<EmergencyReportDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Position? _position;
  bool _isLoadingGps = false;
  bool _isSubmitting = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _captureGps();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'GPS tidak aktif. Nyalakan lokasi lalu coba lagi.';
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'Izin lokasi ditolak.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _position = pos;
        _isLoadingGps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGps = false;
        _gpsError = 'Gagal membaca GPS: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat GPS belum tersedia. Tunggu atau coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reportRepositoryProvider)
          .createEmergencyReport(
            reporterId: user.uid,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : _titleController.text.trim(),
            latitude: _position!.latitude,
            longitude: _position!.longitude,
            severity: ReportSeverity.high,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Laporan Darurat'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buat laporan cepat dari lapangan. Lokasi akan terisi otomatis dari GPS.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Judul Laporan',
                    hintText: 'Misal: Pohon tumbang di Jl. X',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _GpsIndicator(
                  isLoading: _isLoadingGps,
                  position: _position,
                  error: _gpsError,
                  onRetry: _captureGps,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kirim'),
        ),
      ],
    );
  }
}

class _GpsIndicator extends StatelessWidget {
  const _GpsIndicator({
    required this.isLoading,
    required this.position,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final Position? position;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Mendeteksi koordinat...',
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ],
      );
    }
    if (error != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Coba lagi', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
    if (position == null) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lat ${position!.latitude.toStringAsFixed(4)}, '
            'Lng ${position!.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Refresh', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
