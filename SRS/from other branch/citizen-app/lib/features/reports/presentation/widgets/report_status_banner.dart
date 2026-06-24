import 'package:flutter/material.dart';

import '../../domain/entities/report_status.dart';

/// Banner status besar di halaman Detail — warna mengikuti status laporan.
///
/// Memberi konteks cepat ("Menunggu Verifikasi", "Selesai", dll) sebelum user
/// membaca timeline. Dipisah agar pemilihan ikon/teks per status terpusat.
class ReportStatusBanner extends StatelessWidget {
  const ReportStatusBanner({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(status), color: status.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleFor(status),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ReportStatus status) {
    if (status.isResolved) return Icons.check_circle;
    if (status.isRejected) return Icons.cancel;
    if (status.isPending) return Icons.hourglass_top;
    return Icons.autorenew;
  }

  String _subtitleFor(ReportStatus status) {
    if (status.isResolved) return 'Laporan Anda telah diselesaikan.';
    if (status.isRejected) return 'Laporan ditolak oleh petugas.';
    if (status.isPending) return 'Laporan sedang menunggu diverifikasi admin.';
    return 'Laporan Anda sedang dalam proses penanganan.';
  }
}
