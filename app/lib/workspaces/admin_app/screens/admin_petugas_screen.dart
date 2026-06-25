import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/auth/entities/user_role.dart';
import '../../../shared_domain_data/dispatches/providers/dispatch_providers.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../providers/admin_navigation_providers.dart';
import '../widgets/dispatch_form_sheet.dart';
import '../widgets/dialogs/tolak_ajuan_dialog.dart';
import '../widgets/officer_card.dart';

/// Sub-tab internal untuk halaman Petugas.
enum PetugasTab { daftar, permintaan }

extension on PetugasTab {
  String get label {
    switch (this) {
      case PetugasTab.daftar:
        return 'Daftar Petugas';
      case PetugasTab.permintaan:
        return 'Permintaan Tugas';
    }
  }
}

/// Halaman Petugas untuk Admin.
///
/// Dua sub-tab:
///   0. Daftar Petugas   - direktori officer aktif + toggle ketersediaan
///   1. Permintaan Tugas - ajuan diri officer pada laporan tertentu
///
/// Search bar membaca dari `petugasSearchQueryProvider` sehingga pencarian
/// reactive di kedua sub-tab (pola yang sama dengan `penggunaSearchQueryProvider`).
class AdminPetugasScreen extends ConsumerStatefulWidget {
  const AdminPetugasScreen({super.key});

  @override
  ConsumerState<AdminPetugasScreen> createState() => _AdminPetugasScreenState();
}

class _AdminPetugasScreenState extends ConsumerState<AdminPetugasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PetugasTab.values.length,
      vsync: this,
    );
    _searchController = TextEditingController(
      text: ref.read(petugasSearchQueryProvider),
    );

    // Sinkronkan tab dengan provider (untuk deep-link / restore state).
    final initialIndex = ref.read(petugasTabIndexProvider);
    if (initialIndex > 0 && initialIndex < PetugasTab.values.length) {
      _tabController.index = initialIndex;
    }
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(petugasTabIndexProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(petugasSearchQueryProvider);

    return Column(
      children: [
        // Page title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: const Text(
            'Petugas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              ref.read(petugasSearchQueryProvider.notifier).state = v
                  .trim()
                  .toLowerCase();
            },
            decoration: InputDecoration(
              hintText: 'Cari nama / email / no HP / judul laporan...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(petugasSearchQueryProvider.notifier).state =
                            '';
                      },
                    ),
            ),
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade700,
          tabs: [for (final t in PetugasTab.values) Tab(text: t.label)],
        ),

        const Divider(height: 1),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [_DaftarPetugasTab(), _PermintaanTugasTab()],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Sub-tab 1: Daftar Petugas
// ============================================================

class _DaftarPetugasTab extends ConsumerWidget {
  const _DaftarPetugasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeOfficersStreamProvider);
    final filter = ref.watch(petugasAvailabilityFilterProvider);
    final query = ref.watch(petugasSearchQueryProvider);

    return Column(
      children: [
        // Filter chip row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: filter == 'semua',
                onTap: () =>
                    ref.read(petugasAvailabilityFilterProvider.notifier).state =
                        'semua',
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Tersedia',
                selected: filter == 'available',
                onTap: () =>
                    ref.read(petugasAvailabilityFilterProvider.notifier).state =
                        'available',
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Sedang Tugas',
                selected: filter == 'busy',
                onTap: () =>
                    ref.read(petugasAvailabilityFilterProvider.notifier).state =
                        'busy',
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: async.when(
            data: (officers) {
              final filtered = officers.where((o) {
                // Apply availability filter
                if (filter == 'available' && !o.isAvailable) return false;
                if (filter == 'busy' && o.isAvailable) return false;
                // Apply search query
                if (query.isEmpty) return true;
                return o.fullName.toLowerCase().contains(query) ||
                    o.email.toLowerCase().contains(query) ||
                    o.phoneNumber.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Tidak ada petugas yang cocok dengan filter.',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => OfficerCard(
                  officer: filtered[i],
                  onTap: () => context.push(
                    '/admin/petugas/${filtered[i].uid}',
                    extra: filtered[i],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.blue.shade300 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.blue.shade700 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Sub-tab 2: Permintaan Tugas
// ============================================================

class _PermintaanTugasTab extends ConsumerWidget {
  const _PermintaanTugasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingOfficerSelfRequestsStreamProvider);
    final query = ref.watch(petugasSearchQueryProvider);

    return async.when(
      data: (items) {
        final filtered = items.where((entry) {
          if (query.isEmpty) return true;
          return entry.request.officerName.toLowerCase().contains(query) ||
              (entry.report?.title.toLowerCase().contains(query) ?? false);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada permintaan tugas.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _SelfRequestCard(entry: filtered[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SelfRequestCard extends ConsumerWidget {
  const _SelfRequestCard({required this.entry});
  final OfficerSelfRequestWithReport entry;

  String _formatTimestamp(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mn';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = entry.report;
    final locParts = <String>[
      if (report?.district?.isNotEmpty == true) report!.district!,
      if (report?.city?.isNotEmpty == true) report!.city!,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person, color: Colors.blue.shade800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.request.officerName.isEmpty
                          ? 'Officer ${entry.request.officerId.substring(0, 6)}…'
                          : entry.request.officerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ingin menangani laporan:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  '● Menunggu',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Report info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 14,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report?.title ?? '(laporan tidak ditemukan)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (locParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          locParts.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimestamp(entry.request.appliedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onTolak(context, ref),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: report == null
                      ? null
                      : () => _onTerima(context, ref, report),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Terima'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onTolak(BuildContext context, WidgetRef ref) async {
    final reason = await TolakAjuanDialog.show(
      context,
      officerName: entry.request.officerName,
    );
    if (reason == null) return;
    try {
      await ref
          .read(dispatchRepositoryProvider)
          .rejectSelfRequest(
            reportId: entry.request.reportId,
            officerId: entry.request.officerId,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permintaan ditolak.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _onTerima(
    BuildContext context,
    WidgetRef ref,
    ReportEntity report,
  ) async {
    // Ambil UserEntity lengkap untuk officer (perlu untuk DispatchFormSheet).
    final officer = await _resolveOfficer(ref, entry.request.officerId);
    if (officer == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data officer tidak ditemukan.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await DispatchFormSheet.show(
      context,
      report: report,
      initialOfficer: officer,
    );
  }

  Future<UserEntity?> _resolveOfficer(WidgetRef ref, String officerId) async {
    // Ambil snapshot sekali dari user_repository.
    final repo = ref.read(userRepositoryProvider);
    final stream = repo.streamByStatus('active');
    final list = await stream.first;
    try {
      return list.firstWhere(
        (u) => u.uid == officerId && u.role == UserRole.officer,
      );
    } catch (_) {
      return null;
    }
  }
}
