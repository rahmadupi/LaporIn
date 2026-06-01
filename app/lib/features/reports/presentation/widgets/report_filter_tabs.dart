import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/report_history_notifier.dart';

/// Baris tab filter (Semua / Menunggu / Diproses / Selesai) untuk Riwayat.
///
/// Dipisah agar layar Riwayat tidak menggemukkan build-nya. Memanggil
/// [onSelected] saat tab ditekan; tab aktif disorot biru.
class ReportFilterTabs extends StatelessWidget {
  const ReportFilterTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.countFor,
  });

  final ReportFilter selected;
  final ValueChanged<ReportFilter> onSelected;

  /// Callback jumlah laporan per filter untuk ditampilkan di sisi label.
  final int Function(ReportFilter) countFor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReportFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = ReportFilter.values[index];
          final isActive = filter == selected;
          return _FilterChip(
            label: '${filter.label} (${countFor(filter)})',
            isActive: isActive,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
