import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/admin_scaffold.dart';
import '../widgets/priority_alert_card.dart';
import '../widgets/stat_card.dart';

/// Prototype dashboard for the admin workspace.
///
/// Mirrors the layout from `SRS/admin/design/dashboard_screen.png`:
///   - Greeting block
///   - 2x2 summary metric grid
///   - "Hotspot Laporan Terkini" card with a placeholder map view
///   - "Perlu Perhatian Anda" alert list
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _goToUnderConstruction(BuildContext context) {
    context.go('/admin/under-construction');
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentPath: '/admin',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const _GreetingBlock(),
          const SizedBox(height: 20),
          const _StatsGrid(),
          const SizedBox(height: 20),
          _HotspotCard(
            onViewFullMap: () => _goToUnderConstruction(context),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            icon: Icons.priority_high,
            iconColor: Color(0xFFDC2626),
            title: 'Perlu Perhatian Anda',
          ),
          const SizedBox(height: 12),
          PriorityAlertCard(
            severity: AlertSeverity.critical,
            count: 0,
            description: 'Laporan butuh verifikasi segera',
            onTap: () => _goToUnderConstruction(context),
          ),
          const SizedBox(height: 10),
          PriorityAlertCard(
            severity: AlertSeverity.high,
            count: 0,
            description: 'Mendekati batas waktu pengerjaan',
            onTap: () => _goToUnderConstruction(context),
          ),
          const SizedBox(height: 10),
          PriorityAlertCard(
            severity: AlertSeverity.medium,
            count: 0,
            description: 'Menunggu penjadwalan petugas',
            onTap: () => _goToUnderConstruction(context),
          ),
        ],
      ),
    );
  }
}

class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELAMAT PAGI,',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Admin Supervisor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Berikut ringkasan kinerja sistem hari ini.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: const [
        StatCard(
          label: 'Total Laporan Masuk',
          icon: Icons.bar_chart,
          iconColor: Color(0xFF2563EB),
          value: '0',
        ),
        StatCard(
          label: 'Belum Diverifikasi',
          icon: Icons.notifications_active,
          iconColor: Color(0xFFDC2626),
          value: '0',
        ),
        StatCard(
          label: 'Rata-rata Respon',
          icon: Icons.speed,
          iconColor: Color(0xFF7C3AED),
          value: '—',
        ),
        StatCard(
          label: 'Persentase Selesai',
          icon: Icons.check_circle,
          iconColor: Color(0xFF059669),
          value: '—',
        ),
      ],
    );
  }
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({required this.onViewFullMap});

  final VoidCallback onViewFullMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Color(0xFF2563EB),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Hotspot Laporan Terkini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewFullMap,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Lihat Peta Penuh'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _MapPlaceholder(),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          children: [
            // Faint grid lines to suggest a map surface.
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // A few mock heatmap blobs to evoke the cluster preview.
            Positioned(
              left: 24,
              top: 28,
              child: _HeatBlob(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.55),
                  size: 80),
            ),
            Positioned(
              right: 28,
              top: 18,
              child: _HeatBlob(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                  size: 60),
            ),
            Positioned(
              left: 90,
              bottom: 18,
              child: _HeatBlob(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  size: 50),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Color(0xFF6B7280), size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Peta belum tersedia',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatBlob extends StatelessWidget {
  const _HeatBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
