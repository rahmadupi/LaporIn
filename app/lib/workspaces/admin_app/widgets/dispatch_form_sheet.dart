import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/dispatches/providers/dispatch_providers.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';

/// Bottom sheet konfirmasi dispatch.
///
/// Untuk v1: confirm-only (officer & report pre-filled, tidak ada
/// proximity sort). Petugas yang dipilih dapat di-swap dari daftar officer
/// aktif sederhana (diurutkan alfabet). Proximity sort (Geoflutterfire)
/// akan ditambahkan di iterasi berikutnya.
///
/// Submit menjalankan **batched write** di repository (3 dokumen atomic).
class DispatchFormSheet extends ConsumerStatefulWidget {
  const DispatchFormSheet({
    super.key,
    required this.report,
    required this.initialOfficer,
  });

  final ReportEntity report;

  /// Officer yang sudah pre-filled dari ajuan diri (bisa diganti).
  final UserEntity initialOfficer;

  /// Tampilkan sebagai modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required ReportEntity report,
    required UserEntity initialOfficer,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DispatchFormSheet(report: report, initialOfficer: initialOfficer),
    );
  }

  @override
  ConsumerState<DispatchFormSheet> createState() => _DispatchFormSheetState();
}

class _DispatchFormSheetState extends ConsumerState<DispatchFormSheet> {
  late UserEntity _selectedOfficer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedOfficer = widget.initialOfficer;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final admin = ref.read(currentUserProvider).valueOrNull;
      if (admin == null) throw 'Sesi admin tidak ditemukan.';

      await ref
          .read(dispatchRepositoryProvider)
          .acceptSelfRequest(
            reportId: widget.report.reportId,
            officerId: _selectedOfficer.uid,
            assignedBy: admin.uid,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ditugaskan ke ${_selectedOfficer.fullName}.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menugaskan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_turned_in,
                      color: Color(0xFF1D4ED8),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Konfirmasi Penugasan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Laporan'),
                      _ReportSummary(report: widget.report),
                      const SizedBox(height: 20),
                      _SectionLabel('Petugas Lapangan'),
                      _OfficerPicker(
                        selected: _selectedOfficer,
                        onChanged: (o) => setState(() => _selectedOfficer = o),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade900,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tindakan ini akan dijalankan sebagai '
                                'transaksi atomik: status officer, dokumen '
                                'dispatch baru, dan status laporan akan '
                                'diperbarui bersamaan.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _submitting ? 'Memproses...' : 'Konfirmasi Tugaskan',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});
  final ReportEntity report;
  @override
  Widget build(BuildContext context) {
    final locParts = <String>[
      if (report.district?.isNotEmpty == true) report.district!,
      if (report.city?.isNotEmpty == true) report.city!,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (locParts.isNotEmpty)
            Text(
              '📍 ${locParts.join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 4),
          Text(
            'Urgensi: ${report.urgencyLevel.label} • Status: ${report.status.label}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _OfficerPicker extends ConsumerWidget {
  const _OfficerPicker({required this.selected, required this.onChanged});
  final UserEntity selected;
  final ValueChanged<UserEntity> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeOfficersStreamProvider);

    return async.when(
      data: (officers) {
        return Column(
          children: [
            // Selected officer tile
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          selected.email,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        _showSwapSheet(context, officers, selected),
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Officer ini pre-filled dari ajuan diri. Anda dapat mengganti sebelum konfirmasi.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error memuat daftar officer: $e'),
    );
  }

  void _showSwapSheet(
    BuildContext context,
    List<UserEntity> officers,
    UserEntity current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: officers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final o = officers[i];
              final isSelected = o.uid == current.uid;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey,
                  ),
                ),
                title: Text(o.fullName),
                subtitle: Text(o.email),
                trailing: isSelected
                    ? Icon(Icons.check, color: Colors.blue.shade700)
                    : null,
                onTap: () {
                  onChanged(o);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }
}
