import 'package:flutter/material.dart';

import '../../domain/entities/report_status.dart';

/// Badge status laporan: titik berwarna + label, berlatar warna-transparan.
///
/// Reusable di kartu Riwayat (C7) maupun sebagai elemen banner di Detail (C8),
/// sehingga warna & teks status selalu konsisten dari satu sumber
/// ([ReportStatus]).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
