import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/report_card.dart';

/// Citizen Report History (Riwayat Laporan) per
/// [SRS/citizen/feature/citizen_history.md].
///
/// Menampilkan seluruh laporan milik current citizen, semua status.
/// Filter chip (Semua / Pending / Diproses / Selesai / Ditolak).
/// Search bar by judul. Per-item action menu (Edit/Hapus/Banding/Rating)
/// sesuai status — lihat extension `_availableActions()`.
class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  ConsumerState<ReportHistoryScreen> createState() =>
      _ReportHistoryScreenState();
}

enum _Filter { semua, pending, diproses, selesai, ditolak }

extension on _Filter {
  String get label {
    switch (this) {
      case _Filter.semua:
        return 'Semua';
      case _Filter.pending:
        return 'Pending';
      case _Filter.diproses:
        return 'Diproses';
      case _Filter.selesai:
        return 'Selesai';
      case _Filter.ditolak:
        return 'Ditolak';
    }
  }

  bool matches(ReportStatus s) {
    switch (this) {
      case _Filter.semua:
        return true;
      case _Filter.pending:
        return s == ReportStatus.pending;
      case _Filter.diproses:
        return s == ReportStatus.inReview ||
            s == ReportStatus.dispatched ||
            s == ReportStatus.inProgress;
      case _Filter.selesai:
        return s == ReportStatus.resolved;
      case _Filter.ditolak:
        return s == ReportStatus.rejected;
    }
  }
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  _Filter _filter = _Filter.semua;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final asyncMy = ref.watch(myCitizenReportsProvider(user.uid));

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari judul laporan...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Container(
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: _Filter.values.map((f) {
                final isActive = f == _filter;
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
                    onSelected: (_) => setState(() => _filter = f),
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
        ),
        Expanded(
          child: asyncMy.when(
            data: (reports) {
              final filtered = reports.where((r) {
                if (!_filter.matches(r.status)) return false;
                if (_query.isNotEmpty &&
                    !r.title.toLowerCase().contains(_query)) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada laporan. Yuk buat yang pertama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myCitizenReportsProvider(user.uid));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return ReportCard(
                      entity: r,
                      onTap: () => _showActionSheet(context, ref, user.uid, r),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat: $e'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showActionSheet(
    BuildContext context,
    WidgetRef ref,
    String uid,
    ReportEntity r,
  ) {
    final actions = _availableActions(r);
    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada aksi tersedia untuk status ini.'),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.title.isEmpty ? '(Tanpa judul)' : r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...actions.map(
              (a) => ListTile(
                leading: Icon(a.icon, color: a.color),
                title: Text(
                  a.label,
                  style: TextStyle(color: a.color, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await a.onTap();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Aksi yang tersedia sesuai lifecycle status.
  /// - pending: Edit, Hapus
  /// - rejected (≤ 24 jam): Banding
  /// - resolved: Beri Rating
  /// - always: Lihat Detail (planned v1: no-op)
  List<_Action> _availableActions(ReportEntity r) {
    final actions = <_Action>[];
    if (r.status == ReportStatus.pending) {
      actions.add(
        _Action(
          label: 'Edit Deskripsi',
          icon: Icons.edit_outlined,
          color: AppColors.primary,
          onTap: () => _editDescription(r),
        ),
      );
      actions.add(
        _Action(
          label: 'Hapus Laporan',
          icon: Icons.delete_outline,
          color: AppColors.error,
          onTap: () => _confirmDelete(r),
        ),
      );
    }
    if (r.status == ReportStatus.rejected) {
      final ageHours = DateTime.now().difference(r.updatedAt).inHours;
      if (ageHours <= 24) {
        actions.add(
          _Action(
            label: 'Ajukan Banding',
            icon: Icons.gavel_outlined,
            color: AppColors.accent,
            onTap: () => _appeal(r),
          ),
        );
      }
    }
    if (r.status == ReportStatus.resolved) {
      actions.add(
        _Action(
          label: 'Beri Rating',
          icon: Icons.star_outline,
          color: AppColors.accent,
          onTap: () => _rate(r),
        ),
      );
    }
    return actions;
  }

  Future<void> _editDescription(ReportEntity r) async {
    final controller = TextEditingController(text: r.description);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Deskripsi'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    try {
      await ref
          .read(reportRepositoryProvider)
          .updateDescription(r.reportId, result);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deskripsi diperbarui.')));
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal memperbarui: $e');
    }
  }

  Future<void> _confirmDelete(ReportEntity r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text(
          'Laporan akan di-soft-delete. Tindakan ini hanya diizinkan saat '
          'status masih Pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(reportRepositoryProvider).softDelete(r.reportId);
      if (!mounted) return;
      _snackSuccess('Laporan dihapus.');
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal menghapus: $e');
    }
  }

  Future<void> _appeal(ReportEntity r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan Banding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ajukan banding dalam 24 jam setelah penolakan. Jelaskan '
              'mengapa laporan Anda seharusnya tidak ditolak.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Alasan banding...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    try {
      await ref.read(reportRepositoryProvider).submitAppeal(r.reportId, reason);
      if (!mounted) return;
      _snackSuccess('Banding dikirim. Menunggu tinjauan admin.');
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal mengirim banding: $e');
    }
  }

  Future<void> _rate(ReportEntity r) async {
    int stars = 0;
    final commentController = TextEditingController();
    final uid = ref.read(currentUserProvider).valueOrNull?.uid;
    if (uid == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Beri Rating'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final filled = i < stars;
                    return IconButton(
                      icon: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      onPressed: () => setSt(() => stars = i + 1),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Komentar (opsional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Kirim'),
              ),
            ],
          ),
        );
      },
    );
    if (result != true || stars == 0 || !mounted) return;
    try {
      await ref
          .read(reportRepositoryProvider)
          .submitRating(
            reportId: r.reportId,
            reporterId: uid,
            stars: stars,
            comment: commentController.text.trim(),
          );
      if (!mounted) return;
      _snackSuccess('Rating terkirim. Terima kasih!');
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal mengirim rating: $e');
    }
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _snackSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;
  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
