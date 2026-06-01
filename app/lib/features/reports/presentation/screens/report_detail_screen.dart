import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/entities/report.dart';
import '../../domain/report_failure.dart';
import '../../domain/repositories/reports_repository.dart';
import '../widgets/before_after_view.dart';
import '../widgets/edit_description_sheet.dart';
import '../widgets/report_detail_action_bar.dart';
import '../widgets/report_hero_photo.dart';
import '../widgets/report_mini_map.dart';
import '../widgets/report_status_banner.dart';
import '../widgets/report_status_timeline.dart';
import '../widgets/status_badge.dart';

/// Detail Laporan (C8) — "Prompt 7".
///
/// Memakai StreamBuilder atas [ReportsRepository.watchReport] sehingga halaman
/// ikut hidup: bila Admin mengubah status, banner & timeline ter-update tanpa
/// keluar-masuk layar. Aksi Edit/Hapus hanya tersedia saat status `pending`.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late final ReportsRepository _repository =
      context.read<ReportsRepository>();
  late final Stream<Report?> _reportStream =
      _repository.watchReport(widget.reportId);

  bool _isProcessing = false; // True selama proses hapus berjalan.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<Report?>(
        stream: _reportStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.data;
          if (report == null) {
            // Null = dokumen tidak ada / sudah dihapus.
            return const _CenteredMessage(
              icon: Icons.search_off,
              message: 'Laporan tidak ditemukan atau telah dihapus.',
            );
          }
          return _buildContent(report);
        },
      ),
    );
  }

  Widget _buildContent(Report report) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero photo full-bleed di paling atas.
                ReportHeroPhoto(photoUrls: report.photoUrls),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(report),
                      const SizedBox(height: 16),
                      ReportStatusBanner(status: report.status),
                      const SizedBox(height: 24),

                      // ── Lokasi ──────────────────────────────────────
                      const _SectionTitle('Lokasi Kejadian'),
                      const SizedBox(height: 8),
                      Text(
                        report.address.isNotEmpty
                            ? report.address
                            : 'Alamat tidak tersedia',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      ReportMiniMap(
                        latitude: report.latitude,
                        longitude: report.longitude,
                      ),
                      const SizedBox(height: 24),

                      // ── Deskripsi ───────────────────────────────────
                      const _SectionTitle('Deskripsi'),
                      const SizedBox(height: 8),
                      Text(
                        report.description.trim().isNotEmpty
                            ? report.description.trim()
                            : 'Tidak ada deskripsi.',
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 24),

                      // ── Status Timeline ─────────────────────────────
                      const _SectionTitle('Status Laporan'),
                      const SizedBox(height: 16),
                      ReportStatusTimeline(status: report.status),

                      // ── Before/After (hanya bila sudah selesai) ─────
                      if (report.status.isResolved) ...[
                        const SizedBox(height: 24),
                        const _SectionTitle('Dokumentasi Perbaikan'),
                        const SizedBox(height: 12),
                        BeforeAfterView(
                          beforeUrl: report.beforePhotoUrl,
                          afterUrl: report.afterPhotoUrl,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sticky action bar HANYA saat pending (FR-2.4 & FR-2.5).
        if (report.status.isPending)
          ReportDetailActionBar(
            isProcessing: _isProcessing,
            onEdit: () => _onEdit(report),
            onDelete: () => _onDelete(report),
          ),
      ],
    );
  }

  /// Header: kategori, nomor tiket, tanggal, dan badge status.
  Widget _buildHeader(Report report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                report.category.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(status: report.status),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              report.reportId,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Text('•',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Text(
              DateFormatter.dateTime(report.createdAt),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  /// Edit deskripsi: buka sheet, lalu kirim ke repository (validasi pending di
  /// server). Stream akan otomatis menyegarkan tampilan bila sukses.
  Future<void> _onEdit(Report report) async {
    final newDescription = await showEditDescriptionSheet(
      context,
      initialValue: report.description,
    );
    // null = user membatalkan; abaikan.
    if (newDescription == null || !mounted) return;

    try {
      await _repository.updateDescription(
        reportId: report.reportId,
        description: newDescription,
      );
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Deskripsi berhasil diperbarui.');
    } on ReportFailure catch (failure) {
      if (!mounted) return;
      SnackbarHelper.showError(context, failure.message);
    }
  }

  /// Hapus (soft delete): konfirmasi -> set isDeleted=true -> kembali ke Riwayat.
  Future<void> _onDelete(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text(
            'Laporan akan dihapus dari riwayat Anda. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.softDelete(report.reportId);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Laporan berhasil dihapus.');
      // Kembali ke Riwayat; stream watchReport juga akan memancarkan null.
      Navigator.of(context).pop();
    } on ReportFailure catch (failure) {
      if (!mounted) return;
      SnackbarHelper.showError(context, failure.message);
      setState(() => _isProcessing = false);
    }
  }
}

/// Judul section kecil yang konsisten di seluruh halaman detail.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
