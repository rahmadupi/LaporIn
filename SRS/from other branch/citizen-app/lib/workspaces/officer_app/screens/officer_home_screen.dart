import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/emergency_report_dialog.dart';
import '../widgets/officer_task_card.dart';

/// Tab utama Petugas Lapangan — daftar tugas aktif (OFC-002) dengan
/// filter chips (Semua / Belum Dimulai / Sedang Dikerjakan / Mendesak)
/// dan FAB Laporan Darurat (OFC-012).
///
/// Implementasi mengikuti `SRS/officer/feature/officer_home.md` §3 + §5.
/// Data source: stream `/reports` yang difilter
/// `assignedOfficerId == currentUid` dan `status in
/// [dispatched, in_progress]`. Stream disediakan oleh
/// `myAssignedTasksProvider` di shared_domain_data.
class OfficerHomeScreen extends ConsumerStatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  ConsumerState<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends ConsumerState<OfficerHomeScreen> {
  _Filter _filter = _Filter.semua;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sesi login tidak ditemukan.'),
        ),
      );
    }

    final asyncTasks = ref.watch(myAssignedTasksProvider(user.uid));

    return Stack(
      children: [
        Column(
          children: [
            _FilterBar(
              current: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: asyncTasks.when(
                data: (tasks) {
                  final filtered = _applyFilter(tasks);
                  if (filtered.isEmpty) {
                    return _emptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(myAssignedTasksProvider(user.uid));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final task = filtered[i];
                        return OfficerTaskCard(
                          entity: task,
                          onTap: () => _openTask(task),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat tugas: $e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(myAssignedTasksProvider(user.uid)),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // FAB Laporan Darurat (OFC-012)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.report_gmailerrorred),
            label: const Text('Darurat'),
            onPressed: _onEmergency,
          ),
        ),
      ],
    );
  }

  List<ReportEntity> _applyFilter(List<ReportEntity> tasks) {
    switch (_filter) {
      case _Filter.semua:
        return tasks;
      case _Filter.belumDimulai:
        return tasks.where((t) => t.status == ReportStatus.dispatched).toList();
      case _Filter.sedangDikerjakan:
        return tasks.where((t) => t.status == ReportStatus.inProgress).toList();
      case _Filter.mendesak:
        return tasks
            .where(
              (t) =>
                  t.urgencyLevel == ReportUrgency.high ||
                  t.urgencyLevel == ReportUrgency.critical,
            )
            .toList();
    }
  }

  void _openTask(ReportEntity task) {
    // Convert entity → Map<String, dynamic> for the existing Task Detail
    // screen (which takes a Map per the routing extra contract).
    final data = <String, dynamic>{
      'title': task.title,
      'description': task.description,
      'imageUrl':
          task.imageUrl ??
          (task.imageUrls.isNotEmpty ? task.imageUrls.first : null),
      'imageUrls': task.imageUrls,
      'addressDetail': task.addressDetail,
      'urgencyLevel': task.urgencyLevel.value,
      'status': task.status.value,
      'rejectComment': task.rejectComment,
      'proofUrl': task.proofUrl,
      'dispatchedAt': null,
      'createdAt': task.createdAt,
    };
    context.push(AppRoutes.officerTaskDetailFor(task.reportId), extra: data);
  }

  Future<void> _onEmergency() async {
    final ok = await EmergencyReportDialog.show(context);
    if (!mounted || !ok) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    ref.invalidate(myAssignedTasksProvider(user.uid));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Laporan darurat terkirim. Menunggu verifikasi admin.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _emptyState() {
    final msg = _filter == _Filter.semua
        ? 'Tidak ada tugas aktif saat ini.'
        : 'Tidak ada tugas untuk filter ini.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Filter { semua, belumDimulai, sedangDikerjakan, mendesak }

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.semua:
        return 'Semua';
      case _Filter.belumDimulai:
        return 'Belum Dimulai';
      case _Filter.sedangDikerjakan:
        return 'Sedang Dikerjakan';
      case _Filter.mendesak:
        return 'Mendesak';
    }
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});

  final _Filter current;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _Filter.values.map((f) {
            final isActive = f == current;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isActive,
                onSelected: (_) => onChanged(f),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.scaffoldBackground,
                side: BorderSide(
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
