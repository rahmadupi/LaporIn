import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Status siklus hidup sebuah laporan (skema 8.2).
///
/// Selain [slug] (nilai Firestore) dan [label] (teks UI), tiap status membawa
/// [color] untuk badge/banner dan [activeNodeIndex] yang dipakai Status Timeline
/// untuk menentukan sampai node mana progres laporan sudah berjalan.
enum ReportStatus {
  // activeNodeIndex = node yang SEDANG berjalan pada timeline 5-node.
  // Node sebelum index ini dianggap selesai, sesudahnya belum tercapai.
  pending('pending', 'Menunggu Verifikasi', AppColors.accent, 1),
  verified('verified', 'Terverifikasi', AppColors.primary, 2),
  rejected('rejected', 'Ditolak', AppColors.error, 1),
  assigned('assigned', 'Ditugaskan', AppColors.primary, 3),
  inProgress('in_progress', 'Sedang Dikerjakan', AppColors.primary, 3),
  pendingValidation(
      'pending_validation', 'Menunggu Validasi', AppColors.primary, 4),
  resolved('resolved', 'Selesai', AppColors.success, -1), // -1 = semua selesai.
  unknown('unknown', 'Tidak Diketahui', AppColors.textSecondary, 0);

  const ReportStatus(this.slug, this.label, this.color, this.activeNodeIndex);

  final String slug;
  final String label;
  final Color color;

  /// Index node timeline yang sedang aktif (-1 bila seluruh node sudah selesai).
  final int activeNodeIndex;

  static ReportStatus fromSlug(String? value) {
    return values.firstWhere(
      (s) => s.slug == value,
      orElse: () => ReportStatus.unknown,
    );
  }

  bool get isPending => this == ReportStatus.pending;
  bool get isRejected => this == ReportStatus.rejected;
  bool get isResolved => this == ReportStatus.resolved;
}
