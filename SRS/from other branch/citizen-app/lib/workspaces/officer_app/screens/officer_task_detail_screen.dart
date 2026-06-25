import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/officer/data/proof_upload_service.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';
import '../widgets/self_request_button.dart';

/// Halaman detail satu tugas yang ditugaskan ke Petugas Lapangan.
///
/// Mengikuti [SRS/officer/feature/officer_task_detail.md] — layout
/// "Detail Laporan" (hero image, info block, status timeline, action
/// buttons) dengan tombol yang berubah sesuai status saat ini:
/// - `dispatched` → "Mulai Pengerjaan" + "Tolak Tugas"
/// - `in_progress` → "Unggah Bukti" + "Selesaikan" (tanpa bukti, opsional)
/// - `resolved` / `rejected` → read-only
class OfficerTaskDetailScreen extends ConsumerStatefulWidget {
  const OfficerTaskDetailScreen({
    super.key,
    required this.taskId,
    required this.taskData,
    this.readOnly = false,
  });

  final String taskId;
  final Map<String, dynamic> taskData;

  /// Mode read-only dipakai oleh Riwayat (OFC-009). Saat true, semua
  /// action button disembunyikan.
  final bool readOnly;

  @override
  ConsumerState<OfficerTaskDetailScreen> createState() =>
      _OfficerTaskDetailScreenState();
}

class _OfficerTaskDetailScreenState
    extends ConsumerState<OfficerTaskDetailScreen> {
  late final ProofUploadService _service;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = ProofUploadService();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  ReportStatus get _status =>
      ReportStatus.fromString(widget.taskData['status'] as String?);

  // ===========================================================================
  // Action handlers
  // ===========================================================================

  Future<void> _onStart() async {
    setState(() => _busy = true);
    try {
      await _service.markInProgress(widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status diubah ke Pengerjaan.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onReject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Tolak Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berikan alasan penolakan. Admin akan menerima notifikasi.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Misal: Di luar cakupan wilayah saya.',
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
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await _service.rejectTask(widget.taskId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas dikembalikan ke verifikasi.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menolak tugas: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onUploadProof() {
    context.push(
      AppRoutes.officerProofFor(widget.taskId),
      extra: widget.taskData,
    );
  }

  Future<void> _onCompleteWithoutProof() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Tanpa Bukti?'),
        content: const Text(
          'Anda dapat menyelesaikan tugas tanpa foto bukti. Disarankan untuk tetap mengunggah bukti agar admin dapat memvalidasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.commitProofToFirestore(
        taskId: widget.taskId,
        beforeUrl: null,
        afterUrl: null,
        description: null,
        position: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tugas ditandai selesai.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final data = widget.taskData;
    final title = (data['title'] as String?) ?? 'Tanpa Judul';
    final description =
        (data['description'] as String?) ?? 'Tidak ada deskripsi.';
    final heroImage =
        (data['imageUrl'] as String?) ??
        (data['imageUrls'] is List && (data['imageUrls'] as List).isNotEmpty
            ? (data['imageUrls'] as List).first as String
            : null);
    final location =
        data['addressDetail'] as String? ??
        (data['location'] is Map
            ? _formatLatLng(
                (data['location'] as Map)['latitude'],
                (data['location'] as Map)['longitude'],
              )
            : 'Lokasi tidak diketahui');
    final urgency = ReportUrgency.fromString(data['urgencyLevel'] as String?);
    final dispatchedAt = (data['dispatchedAt'] != null)
        ? _formatDate(data['dispatchedAt'])
        : null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: heroImage != null && heroImage.isNotEmpty
                  ? Image.network(
                      heroImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderHero(),
                    )
                  : _placeholderHero(),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(status: _status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetaRow(icon: Icons.place_outlined, text: location),
                  if (dispatchedAt != null) ...[
                    const SizedBox(height: 6),
                    _MetaRow(
                      icon: Icons.event_outlined,
                      text: 'Ditugaskan: $dispatchedAt',
                    ),
                  ],
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.flag_outlined,
                    text: 'Urgensi: ${urgency.label}',
                    textColor: _urgencyColor(urgency),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status timeline
                  const Text(
                    'Status Laporan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusTimeline(current: _status),

                  const SizedBox(height: 24),

                  // Self-request CTA — hanya untuk laporan yang BELUM
                  // di-assign ke officer ini dan statusnya masih
                  // `pending` atau `in_review`.
                  if (_shouldShowSelfRequest(data))
                    _SelfRequestCard(reportId: widget.taskId),

                  const SizedBox(height: 24),

                  // Bukti penyelesaian — link/CTA ke proof screen
                  _ProofSummaryCard(
                    proofUrl: data['proofUrl'] as String?,
                    photoBeforeUrl: data['photoBeforeUrl'] as String?,
                    photoAfterUrl: data['photoAfterUrl'] as String?,
                    proofDescription: data['proofDescription'] as String?,
                    status: _status,
                    onUpload: widget.readOnly ? null : _onUploadProof,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildActionBar(),
              ),
            ),
    );
  }

  Widget _buildActionBar() {
    if (_busy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_status) {
      case ReportStatus.dispatched:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onReject,
                icon: const Icon(Icons.close, color: AppColors.error),
                label: const Text(
                  'Tolak',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mulai Pengerjaan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      case ReportStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onCompleteWithoutProof,
                icon: const Icon(Icons.check),
                label: const Text('Selesaikan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _onUploadProof,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Unggah Bukti'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        );
      default:
        // resolved / rejected / in_review / pending → read-only
        return const SizedBox.shrink();
    }
  }

  Widget _placeholderHero() => Container(
    color: AppColors.border,
    child: const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Color _urgencyColor(ReportUrgency urgency) {
    switch (urgency) {
      case ReportUrgency.critical:
        return AppColors.error;
      case ReportUrgency.high:
        return AppColors.accent;
      case ReportUrgency.medium:
        return AppColors.primary;
      case ReportUrgency.low:
        return AppColors.success;
    }
  }

  String _formatLatLng(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return 'Lokasi tidak diketahui';
    return 'Lat ${(lat as num).toStringAsFixed(4)}, Lng ${(lng as num).toStringAsFixed(4)}';
  }

  /// Self-request CTA ditampilkan untuk laporan yang:
  /// - status `pending` atau `in_review` (belum ada officer yang ditugaskan)
  /// - belum di-assign ke officer yang sedang login
  /// - tidak dalam mode read-only (Riwayat)
  bool _shouldShowSelfRequest(Map<String, dynamic> data) {
    if (widget.readOnly) return false;
    if (_status != ReportStatus.pending && _status != ReportStatus.inReview) {
      return false;
    }
    final assigned = (data['assignedOfficerId'] as String?)?.trim();
    if (assigned == null || assigned.isEmpty) return true;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return false;
    return assigned != user.uid;
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '-';
    if (ts is DateTime) {
      return '${ts.day}/${ts.month}/${ts.year}';
    }
    // Firestore Timestamp duck-typed
    try {
      final dt = (ts as dynamic).toDate() as DateTime?;
      if (dt == null) return '-';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.textColor});

  final IconData icon;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _bg(), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _bg(),
            ),
          ),
        ],
      ),
    );
  }

  Color _bg() {
    switch (status) {
      case ReportStatus.resolved:
        return AppColors.success;
      case ReportStatus.inProgress:
        return AppColors.primary;
      case ReportStatus.dispatched:
        return AppColors.accent;
      case ReportStatus.inReview:
        return AppColors.accent;
      case ReportStatus.rejected:
        return AppColors.error;
      case ReportStatus.pending:
        return AppColors.textSecondary;
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.current});

  final ReportStatus current;

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        'Laporan Terkirim',
        'Laporan diterima sistem',
        ReportStatus.pending,
      ),
      _TimelineStep('Verifikasi', 'Sedang berlangsung', ReportStatus.inReview),
      _TimelineStep(
        'Penugasan',
        'Laporan ditugaskan ke petugas',
        ReportStatus.dispatched,
      ),
      _TimelineStep(
        'Pengerjaan',
        'Petugas memperbaiki kerusakan',
        ReportStatus.inProgress,
      ),
      _TimelineStep(
        'Selesai',
        'Perbaikan selesai & divalidasi',
        ReportStatus.resolved,
      ),
    ];

    final order = [
      ReportStatus.pending,
      ReportStatus.inReview,
      ReportStatus.dispatched,
      ReportStatus.inProgress,
      ReportStatus.resolved,
    ];
    final currentIndex = order.indexOf(current);
    final isRejected = current == ReportStatus.rejected;

    return Column(
      children: List.generate(steps.length, (i) {
        final isReached = !isRejected && i <= currentIndex;
        final isCurrent = !isRejected && i == currentIndex;
        return _TimelineRow(
          step: steps[i],
          isReached: isReached,
          isCurrent: isCurrent,
          isLast: i == steps.length - 1,
        );
      }),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final ReportStatus matches;
  const _TimelineStep(this.title, this.subtitle, this.matches);
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isReached,
    required this.isCurrent,
    required this.isLast,
  });

  final _TimelineStep step;
  final bool isReached;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isReached ? AppColors.primary : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connector column
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isReached ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isCurrent
                      ? const Icon(Icons.circle, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: color)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isReached
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
}

/// Card berisi CTA "Saya Ingin Menangani" untuk laporan yang BELUM
/// di-assign ke officer yang sedang login. Ditampilkan hanya saat
/// status `pending` atau `in_review`.
class _SelfRequestCard extends StatelessWidget {
  const _SelfRequestCard({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.front_hand, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Tangani Laporan Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Laporan ini belum ditugaskan. Ajukan diri Anda untuk menangani; '
            'admin akan meninjaunya.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SelfRequestButton(reportId: reportId),
        ],
      ),
    );
  }
}

class _ProofSummaryCard extends StatelessWidget {
  const _ProofSummaryCard({
    required this.proofUrl,
    required this.photoBeforeUrl,
    required this.photoAfterUrl,
    required this.proofDescription,
    required this.status,
    required this.onUpload,
  });

  final String? proofUrl;
  final String? photoBeforeUrl;
  final String? photoAfterUrl;
  final String? proofDescription;
  final ReportStatus status;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final hasProof =
        (proofUrl != null && proofUrl!.isNotEmpty) ||
        (photoBeforeUrl != null && photoBeforeUrl!.isNotEmpty) ||
        (photoAfterUrl != null && photoAfterUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                Icons.photo_camera_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Bukti Penyelesaian',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (hasProof)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Terunggah',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasProof)
            const Text(
              'Belum ada bukti. Unggah foto sebelum & sesudah pengerjaan untuk menutup tugas.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else ...[
            if (photoBeforeUrl != null) _thumb('Sebelum', photoBeforeUrl!),
            if (photoAfterUrl != null) _thumb('Sesudah', photoAfterUrl!),
            if (proofDescription != null && proofDescription!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                proofDescription!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
          if (onUpload != null &&
              (status == ReportStatus.dispatched ||
                  status == ReportStatus.inProgress)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload),
                label: Text(hasProof ? 'Edit Bukti' : 'Unggah Bukti'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _thumb(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.border,
                child: const Icon(
                  Icons.broken_image,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Foto $label',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
