import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/reports_repository.dart';
import '../providers/report_history_notifier.dart';
import '../widgets/report_filter_tabs.dart';
import '../widgets/report_list_card.dart';
import 'report_detail_screen.dart';

/// Riwayat Laporan (C7).
///
/// Menyediakan [ReportHistoryNotifier] (yang membuka stream Firestore) hanya
/// selama layar ini hidup, lalu menampilkan daftar + filter tabs. UID diambil
/// dari AuthProvider untuk mem-filter laporan milik user yang login.
class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return ChangeNotifierProvider(
      // Notifier dibuat di sini agar stream otomatis ditutup saat layar ditutup.
      create: (ctx) => ReportHistoryNotifier(
        repository: ctx.read<ReportsRepository>(),
        reporterId: uid,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Laporan',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: const _HistoryBody(),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    // watch: rebuild saat data stream masuk / filter berganti.
    final notifier = context.watch<ReportHistoryNotifier>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ReportFilterTabs(
            selected: notifier.filter,
            onSelected: notifier.setFilter,
            countFor: notifier.countFor,
          ),
        ),
        Expanded(child: _buildContent(context, notifier)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ReportHistoryNotifier notifier) {
    switch (notifier.status) {
      case HistoryStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case HistoryStatus.error:
        return _CenteredMessage(
          icon: Icons.cloud_off,
          message: notifier.error ?? 'Terjadi kesalahan.',
        );
      case HistoryStatus.loaded:
        final reports = notifier.visibleReports;
        if (reports.isEmpty) {
          return const _CenteredMessage(
            icon: Icons.inbox_outlined,
            message: 'Belum ada laporan pada kategori ini.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ReportListCard(
              report: report,
              // Buka Detail (C8) sambil mengoper reportId untuk di-stream ulang.
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ReportDetailScreen(reportId: report.reportId),
                ),
              ),
            );
          },
        );
    }
  }
}

/// Tampilan tengah untuk kondisi kosong/error.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
