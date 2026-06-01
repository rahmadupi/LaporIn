import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/report_status.dart';

/// Status sebuah node pada timeline.
enum _NodeState { completed, active, rejected, upcoming }

/// Status Timeline vertikal 5-node di Detail (C8).
///
/// Memetakan satu [ReportStatus] menjadi progres 5 tahap baku siklus laporan.
/// Lihat [_stages] untuk daftar tahapnya; status -> node aktif ditentukan oleh
/// [ReportStatus.activeNodeIndex].
class ReportStatusTimeline extends StatelessWidget {
  const ReportStatusTimeline({super.key, required this.status});

  final ReportStatus status;

  // Lima tahap baku. Indeks-nya selaras dengan ReportStatus.activeNodeIndex.
  static const List<({String title, String subtitle})> _stages = [
    (title: 'Laporan Terkirim', subtitle: 'Laporan diterima sistem'),
    (title: 'Verifikasi', subtitle: 'Admin memeriksa keabsahan laporan'),
    (title: 'Penugasan', subtitle: 'Laporan ditugaskan ke petugas'),
    (title: 'Pengerjaan', subtitle: 'Petugas memperbaiki kerusakan'),
    (title: 'Selesai', subtitle: 'Perbaikan selesai & divalidasi'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // List.generate membangun tiap node; isLast mematikan garis penghubung
      // di node terakhir.
      children: List.generate(_stages.length, (index) {
        final stage = _stages[index];
        final state = _stateFor(index, status);
        final isLast = index == _stages.length - 1;
        return _TimelineNode(
          title: stage.title,
          subtitle: stage.subtitle,
          state: state,
          isLast: isLast,
        );
      }),
    );
  }

  /// Menentukan kondisi node ke-[i] berdasarkan node aktif dari status.
  ///
  /// - resolved (activeNodeIndex == -1): semua node dianggap selesai.
  /// - i < aktif  : sudah dilewati (completed).
  /// - i == aktif : node berjalan (active), atau rejected bila status ditolak.
  /// - i > aktif  : belum tercapai (upcoming).
  _NodeState _stateFor(int i, ReportStatus status) {
    final active = status.activeNodeIndex;
    if (active == -1) return _NodeState.completed;
    if (i < active) return _NodeState.completed;
    if (i == active) {
      return status.isRejected ? _NodeState.rejected : _NodeState.active;
    }
    return _NodeState.upcoming;
  }
}

/// Satu baris node: kolom kiri (dot + garis) dan kolom kanan (teks).
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final _NodeState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _color(state);
    // Garis penghubung berwarna hanya bila node ini sudah selesai; node aktif
    // ke bawah masih abu-abu karena tahap berikutnya belum tercapai.
    final connectorColor =
        state == _NodeState.completed ? AppColors.primary : AppColors.border;

    // IntrinsicHeight agar garis (Expanded) meregang setinggi konten teks.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _Dot(state: state, color: color),
              if (!isLast)
                Expanded(child: Container(width: 2, color: connectorColor)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              // Beri jarak antar-node, kecuali setelah node terakhir.
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: state == _NodeState.upcoming
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: state == _NodeState.upcoming
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state == _NodeState.active
                        ? 'Sedang berlangsung'
                        : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: state == _NodeState.active
                          ? color
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(_NodeState state) {
    switch (state) {
      case _NodeState.completed:
        return AppColors.primary;
      case _NodeState.active:
        return AppColors.accent;
      case _NodeState.rejected:
        return AppColors.error;
      case _NodeState.upcoming:
        return AppColors.border;
    }
  }
}

/// Lingkaran penanda node: terisi + ikon untuk selesai/ditolak, cincin untuk
/// aktif, dan lingkaran kosong untuk yang belum tercapai.
class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.color});

  final _NodeState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _NodeState.completed:
        return _circle(child: const Icon(Icons.check, size: 14, color: Colors.white));
      case _NodeState.rejected:
        return _circle(child: const Icon(Icons.close, size: 14, color: Colors.white));
      case _NodeState.active:
        // Cincin: lingkaran berwarna dengan inti putih agar terlihat "berdenyut".
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      case _NodeState.upcoming:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        );
    }
  }

  /// Lingkaran penuh berwarna [color] berisi [child] (ikon).
  Widget _circle({required Widget child}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}
