import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_severity.dart';
import '../providers/report_form_notifier.dart';
import '../widgets/report_step_scaffold.dart';

/// Lapor Step 4 — Form Detail: deskripsi, severity, dan toggle Lapor Anonim.
///
/// StatefulWidget karena memegang [TextEditingController] untuk deskripsi.
/// Step ini selalu "valid" (deskripsi opsional, severity punya default), jadi
/// tombol "Lanjut ke Preview" tidak pernah disabled.
class Step4DetailScreen extends StatefulWidget {
  const Step4DetailScreen({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step4DetailScreen> createState() => _Step4DetailScreenState();
}

class _Step4DetailScreenState extends State<Step4DetailScreen> {
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    // Isi awal dari notifier agar deskripsi tidak hilang saat user mundur lalu
    // kembali ke step ini.
    _descController =
        TextEditingController(text: context.read<ReportFormNotifier>().description);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReportFormNotifier>();

    return ReportStepScaffold(
      currentStep: 4,
      title: 'Detail Laporan',
      subtitle: 'Lengkapi keterangan agar laporan lebih mudah ditindaklanjuti.',
      primaryLabel: 'Lanjut ke Preview',
      onBack: widget.onBack,
      // Sebelum maju, simpan teks deskripsi terbaru ke notifier.
      onPrimary: () {
        notifier.setDescription(_descController.text);
        widget.onNext();
      },
      child: ListView(
        children: [
          // ── Deskripsi (opsional) ──────────────────────────────────────
          const _Label('Deskripsi (opsional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 4,
            maxLength: 280, // Sesuai batas field `description` (skema 8.2).
            decoration: const InputDecoration(
              hintText: 'Contoh: Lubang besar di tengah jalan, berbahaya...',
            ),
          ),
          const SizedBox(height: 8),

          // ── Severity ──────────────────────────────────────────────────
          const _Label('Tingkat Keparahan'),
          const SizedBox(height: 8),
          Row(
            children: ReportSeverity.values.map((severity) {
              final isSelected = notifier.severity == severity;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: severity == ReportSeverity.high ? 0 : 8),
                  child: _SeverityChip(
                    severity: severity,
                    isSelected: isSelected,
                    onTap: () => notifier.setSeverity(severity),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Toggle Lapor Anonim (FR-2.2) ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              value: notifier.isAnonymous,
              onChanged: notifier.toggleAnonymous,
              activeThumbColor: AppColors.primary,
              title: const Text('Lapor Anonim',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                'Identitas Anda disembunyikan dari publik.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          // Info box muncul hanya saat anonim aktif, menjelaskan konsekuensinya.
          if (notifier.isAnonymous) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laporan anonim tetap diverifikasi sistem, tetapi Anda '
                      'tidak akan menerima notifikasi perkembangan status.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Label section kecil yang konsisten di seluruh form.
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Chip pemilih tingkat keparahan; mewarnai diri sesuai [ReportSeverity.color].
class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.severity,
    required this.isSelected,
    required this.onTap,
  });

  final ReportSeverity severity;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? severity.color.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? severity.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          severity.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? severity.color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
