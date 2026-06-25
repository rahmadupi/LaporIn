import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/auth/entities/user_role.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/dispatches/providers/dispatch_providers.dart';
import '../widgets/dialogs/ban_user_dialog.dart';

/// Read-only profile view untuk officer, diakses dari halaman Petugas.
///
/// Aksi:
///   - Toggle ketersediaan (`isAvailable`)
///   - Ban / Unban officer
///   - Lihat daftar dispatch aktif officer (read-only, dengan tautan
///     ke report — drill-in ditangguhkan ke v2)
class OfficerProfileViewScreen extends ConsumerWidget {
  const OfficerProfileViewScreen({super.key, required this.officer});

  final UserEntity officer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeDispatchesByOfficerProvider(officer.uid));
    final activeJobs = async.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Petugas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin/petugas'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(officer: officer),
            const SizedBox(height: 16),
            _InfoTile(label: 'Email', value: officer.email, icon: Icons.email),
            _InfoTile(
              label: 'Nomor HP',
              value: officer.phoneNumber.isEmpty ? '-' : officer.phoneNumber,
              icon: Icons.phone,
            ),
            _InfoTile(
              label: 'Role',
              value: officer.role == UserRole.officer ? 'Petugas' : 'Lainnya',
              icon: Icons.badge,
            ),
            _InfoTile(
              label: 'Status',
              value: officer.status,
              icon: Icons.verified_user,
            ),
            _InfoTile(
              label: 'Ketersediaan',
              value: officer.isAvailable ? 'Tersedia' : 'Sedang Tugas',
              icon: Icons.work_outline,
            ),
            _InfoTile(
              label: 'Tugas Aktif',
              value: '$activeJobs',
              icon: Icons.assignment,
            ),
            _InfoTile(
              label: 'Terdaftar',
              value: _formatDate(officer.createdAt),
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 24),
            if (officer.isBanned && officer.banReason != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.block, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diblokir${officer.bannedBy != null ? ' oleh admin' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                          if (officer.bannedAt != null)
                            Text(
                              _formatDate(officer.bannedAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Alasan: ${officer.banReason}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Aksi Moderasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (officer.isBanned)
                  OutlinedButton.icon(
                    onPressed: () => _onUnban(context, ref),
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Unban'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _onBan(context, ref),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Ban'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onBan(BuildContext context, WidgetRef ref) async {
    final reason = await BanUserDialog.show(
      context,
      userName: officer.fullName,
    );
    if (reason == null) return;
    final admin = ref.read(currentUserProvider).valueOrNull;
    if (admin == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .ban(uid: officer.uid, reason: reason, bannedBy: admin.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengguna diblokir.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _onUnban(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buka Blokir'),
        content: Text('Buka blokir untuk ${officer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unban'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(userRepositoryProvider).unban(officer.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengguna di-unban.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.officer});
  final UserEntity officer;

  String _initials() {
    final parts = officer.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            _initials(),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                officer.fullName.isEmpty ? officer.email : officer.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UID: ${officer.uid.substring(0, officer.uid.length.clamp(0, 8))}…',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper untuk ambil satu officer by uid (untuk navigasi via go_router).
final officerByIdProvider = StreamProvider.family<UserEntity?, String>((
  ref,
  uid,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data() as Map<String, dynamic>;
        return UserEntity(
          uid: data['uid'] ?? doc.id,
          fullName: data['fullName'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          role: UserRole.fromString(data['role']),
          fcmToken: data['fcmToken'],
          status: data['status'] ?? 'active',
          isAvailable: data['isAvailable'] ?? true,
          banReason: data['banReason'],
          bannedAt: (data['bannedAt'] as Timestamp?)?.toDate(),
          bannedBy: data['bannedBy'],
          approvedBy: data['approvedBy'],
          approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      });
});
