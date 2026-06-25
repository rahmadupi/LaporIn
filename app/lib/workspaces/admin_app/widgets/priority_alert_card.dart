import 'package:flutter/material.dart';

/// Visual severity tiers used by [PriorityAlertCard].
enum AlertSeverity {
  critical('KRITIS', Color(0xFFDC2626), Color(0xFFFEE2E2), Icons.warning_amber),
  high('TINGGI', Color(0xFFEA580C), Color(0xFFFFEDD5), Icons.priority_high),
  medium('SEDANG', Color(0xFFCA8A04), Color(0xFFFEF3C7), Icons.schedule),
  low('RENDAH', Color(0xFF16A34A), Color(0xFFDCFCE7), Icons.info_outline);

  const AlertSeverity(this.label, this.accent, this.soft, this.icon);

  final String label;
  final Color accent;
  final Color soft;
  final IconData icon;
}

/// Card used in the "Perlu Perhatian Anda" section to surface overdue
/// reports grouped by severity.
class PriorityAlertCard extends StatelessWidget {
  const PriorityAlertCard({
    super.key,
    required this.severity,
    required this.count,
    required this.description,
    this.onTap,
  });

  final AlertSeverity severity;
  final int count;
  final String description;
  final VoidCallback? onTap;

  static String _buildTitle(AlertSeverity severity, int count) {
    switch (severity) {
      case AlertSeverity.critical:
        return '$count Laporan Kritis';
      case AlertSeverity.high:
        return '$count Laporan Prioritas Tinggi';
      case AlertSeverity.medium:
        return '$count Laporan Prioritas Sedang';
      case AlertSeverity.low:
        return '$count Laporan Prioritas Rendah';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: severity.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(severity.icon, color: severity.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildTitle(severity, count),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: severity.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
