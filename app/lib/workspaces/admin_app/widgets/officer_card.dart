import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/dispatches/providers/dispatch_providers.dart';

/// Kartu reusable untuk menampilkan ringkasan officer.
///
/// Dipakai di:
///   - Petugas → Daftar Petugas (toggle isAvailable inline)
///   - Bisa juga dipakai dari halaman lain (reassign, dll.)
class OfficerCard extends ConsumerWidget {
  const OfficerCard({
    super.key,
    required this.officer,
    this.trailing,
    this.onTap,
    this.showActiveJobCount = true,
  });

  final UserEntity officer;

  /// Widget tambahan di sisi kanan (mis. menu, tombol Detail).
  final Widget? trailing;

  /// Tap handler untuk body card.
  final VoidCallback? onTap;

  /// Tampilkan jumlah tugas aktif (watch dispatch stream).
  final bool showActiveJobCount;

  String _initials() {
    final parts = officer.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _toggleAvailability(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(userRepositoryProvider)
          .setAvailability(uid: officer.uid, isAvailable: !officer.isAvailable);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              officer.isAvailable
                  ? '${officer.fullName} ditandai Sedang Tugas.'
                  : '${officer.fullName} ditandai Tersedia.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah ketersediaan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvail = officer.isAvailable;
    final availabilityColor = isAvail ? Colors.green : Colors.orange;
    final availabilityFg = isAvail
        ? Colors.green.shade700
        : Colors.orange.shade800;
    final availabilityBorder = isAvail
        ? Colors.green.shade300
        : Colors.orange.shade300;
    final availabilityLabel = isAvail ? 'Tersedia' : 'Sedang Tugas';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _initials(),
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          officer.fullName.isEmpty
                              ? officer.email
                              : officer.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (showActiveJobCount) _ActiveJobCount(uid: officer.uid),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📞 ${officer.phoneNumber.isEmpty ? '-' : officer.phoneNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    '✉ ${officer.email}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleAvailability(context, ref),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: availabilityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: availabilityBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvail
                                    ? Icons.check_circle
                                    : Icons.work_history,
                                size: 14,
                                color: availabilityFg,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                availabilityLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: availabilityFg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Widget kecil: badge jumlah tugas aktif per officer (live).
class _ActiveJobCount extends ConsumerWidget {
  const _ActiveJobCount({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeDispatchesByOfficerProvider(uid));
    final count = async.maybeWhen(data: (list) => list.length, orElse: () => 0);
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment, size: 12, color: Colors.amber.shade900),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
