import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/report_category.dart';
import '../providers/report_form_notifier.dart';
import '../widgets/category_grid_tile.dart';
import '../widgets/report_step_scaffold.dart';

/// Lapor Step 1 — Pilih Kategori (grid).
///
/// Hanya menulis [ReportFormNotifier.setCategory] dan mengaktifkan "Lanjut"
/// ketika sudah ada kategori terpilih. Navigasi maju/mundur diserahkan ke flow
/// lewat callback [onNext]/[onBack] agar step ini tidak tahu urutan layar.
class Step1CategoryScreen extends StatelessWidget {
  const Step1CategoryScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // watch: rebuild saat kategori berubah agar highlight & tombol ikut update.
    final notifier = context.watch<ReportFormNotifier>();

    return ReportStepScaffold(
      currentStep: 1,
      title: 'Pilih Kategori',
      subtitle: 'Apa jenis kerusakan yang Anda temukan?',
      primaryLabel: 'Lanjut',
      onBack: onBack,
      // Tombol disabled (null) sampai satu kategori dipilih.
      onPrimary: notifier.isStep1Valid ? onNext : null,
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
        children: ReportCategory.values.map((category) {
          return CategoryGridTile(
            category: category,
            isSelected: notifier.category == category,
            onTap: () => notifier.setCategory(category),
          );
        }).toList(),
      ),
    );
  }
}
