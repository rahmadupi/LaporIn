import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/report_card.dart';

/// Citizen Laporan (Public Feed) per
/// [SRS/citizen/feature/citizen_laporan.md].
///
/// Feed publik berisi laporan orang lain (exclude milik sendiri),
/// dengan status visible (semua kecuali `rejected`). Filter chip:
/// Semua / Pending / Diproses / Selesai. Search bar by judul.
class CitizenLaporanScreen extends ConsumerStatefulWidget {
  const CitizenLaporanScreen({super.key});

  @override
  ConsumerState<CitizenLaporanScreen> createState() =>
      _CitizenLaporanScreenState();
}

enum _Filter { semua, pending, diproses, selesai }

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
    }
  }
}

class _CitizenLaporanScreenState extends ConsumerState<CitizenLaporanScreen> {
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
    final asyncFeed = ref.watch(publicReportsFeedProvider(user.uid));

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
          child: asyncFeed.when(
            data: (reports) {
              final filtered = reports.where((r) {
                if (!_filter.matches(r.status)) {
                  return false;
                }
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
                          Icons.public,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada laporan publik di area Anda.',
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
                  ref.invalidate(publicReportsFeedProvider(user.uid));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => ReportCard(
                    entity: filtered[i],
                    onTap: () {
                      // v1: citizen report detail belum ada; tap = no-op
                    },
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat feed: $e'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
