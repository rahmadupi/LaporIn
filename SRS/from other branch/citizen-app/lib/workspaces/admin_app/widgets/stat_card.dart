import 'package:flutter/material.dart';

/// A summary metric card used in the dashboard grid.
///
/// Layout (top to bottom):
/// - Small accent-coloured icon badge (top-left)
/// - Large metric value (middle, FittedBox to shrink if too big)
/// - Short label (bottom, max 2 lines + ellipsis)
///
/// Designed to gracefully handle long labels like "Total Laporan
/// Diverifikasi" without overflowing on narrow grid cells.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.value,
  });

  /// Short caption describing the metric (e.g. "Total Laporan Masuk").
  final String label;

  /// Material icon to render inside the accent badge.
  final IconData icon;

  /// Colour for both the icon and its rounded background.
  final Color iconColor;

  /// Optional metric value. When null, the card shows a placeholder dash.
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),

          // Value (shrinks via FittedBox to avoid horizontal overflow)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? '—',
              maxLines: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                height: 1.1,
              ),
            ),
          ),

          // Label (wraps to 2 lines max with ellipsis)
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
