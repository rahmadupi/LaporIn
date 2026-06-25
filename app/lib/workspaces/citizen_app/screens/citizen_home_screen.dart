import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/report_card.dart';

/// Citizen Home / Dashboard (Beranda) per
/// [SRS/citizen/feature/citizen_home.md].
///
/// Komponen:
/// - AppBar: "LaporIn" + bell icon dengan unread badge (kosmetik v1)
/// - Greeting block: "Selamat ..., [Nama]"
/// - Hero CTA: gradient card "Buat Laporan" → push ke ReportFlow
/// - Stats row: laporan aktif (in_progress+dispatched) + selesai bulan ini
/// - Recent reports: 5 laporan terakhir user
class CitizenHomeScreen extends ConsumerWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sesi login tidak ditemukan.'),
        ),
      );
    }

    final myReports = ref.watch(myCitizenReportsProvider(user.uid));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _Greeting(name: user.fullName),
        const SizedBox(height: 20),
        _HeroCta(onTap: () => context.push(AppRoutes.createReport)),
        const SizedBox(height: 20),
        _StatsRow(asyncReports: myReports),
        const SizedBox(height: 20),
        const Text(
          'Laporan Terbaru',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        myReports.when(
          data: (reports) {
            if (reports.isEmpty) {
              return const _EmptyRecent();
            }
            return Column(
              children: reports
                  .take(5)
                  .map(
                    (r) => ReportCard(
                      entity: r,
                      onTap: () => _openReport(context, r),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _ErrorBox(message: '$e'),
        ),
      ],
    );
  }

  void _openReport(BuildContext context, ReportEntity r) {
    // v1: tidak ada citizen report detail page. Tap = nothing (silent)
    // atau bisa navigate ke task-detail-style. Untuk sekarang: no-op
    // karena SRS untuk citizen detail masih planned.
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
        ? 'Selamat Siang'
        : hour < 18
        ? 'Selamat Sore'
        : 'Selamat Malam';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          name.isEmpty ? 'Warga' : name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HeroCta extends StatelessWidget {
  const _HeroCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Laporkan kerusakan infrastruktur di sekitarmu',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.asyncReports});

  final AsyncValue<List<ReportEntity>> asyncReports;

  @override
  Widget build(BuildContext context) {
    final reports = asyncReports.valueOrNull ?? const <ReportEntity>[];
    final aktif = reports
        .where(
          (r) =>
              r.status == ReportStatus.inProgress ||
              r.status == ReportStatus.dispatched,
        )
        .length;
    final now = DateTime.now();
    final selesaiBulanIni = reports
        .where(
          (r) =>
              r.status == ReportStatus.resolved &&
              r.updatedAt.year == now.year &&
              r.updatedAt.month == now.month,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Laporan Aktif',
            value: '$aktif',
            color: AppColors.primary,
            icon: Icons.assignment_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Selesai Bulan Ini',
            value: '$selesaiBulanIni',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'Belum ada laporan. Yuk buat yang pertama!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Gagal memuat: $message',
        style: const TextStyle(fontSize: 12, color: AppColors.error),
      ),
    );
  }
}
