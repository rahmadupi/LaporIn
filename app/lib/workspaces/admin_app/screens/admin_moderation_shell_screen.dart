import 'package:flutter/material.dart';

import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import 'admin_laporan_list_screen.dart';
import 'admin_pengguna_screen.dart';

/// Moderation shell — halaman dengan tab switcher
/// `Laporan | Pengguna` di bagian atas.
class AdminModerationShellScreen extends StatefulWidget {
  const AdminModerationShellScreen({
    super.key,
    this.initialFilter,
    this.initialUrgency,
  });

  final LaporanFilter? initialFilter;

  /// Initial urgency filter parsed from URL query string.
  final ReportUrgency? initialUrgency;

  @override
  State<AdminModerationShellScreen> createState() =>
      _AdminModerationShellScreenState();
}

class _AdminModerationShellScreenState extends State<AdminModerationShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Text(
            'Moderasi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),

        // Tab pill switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Laporan'),
                Tab(text: 'Pengguna'),
              ],
            ),
          ),
        ),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AdminLaporanListScreen(
                initialFilter: widget.initialFilter,
                initialUrgency: widget.initialUrgency,
              ),
              const AdminPenggunaScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
