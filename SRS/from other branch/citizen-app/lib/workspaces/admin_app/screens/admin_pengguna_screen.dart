import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared_domain_data/auth/data/repositories/user_repository.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/auth/entities/user_role.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../providers/admin_navigation_providers.dart';

/// Sub-tab internal untuk halaman Pengguna.
enum PenggunaTab { aktif, diblokir, persetujuan, dormant }

extension on PenggunaTab {
  String get label {
    switch (this) {
      case PenggunaTab.aktif:
        return 'Aktif';
      case PenggunaTab.diblokir:
        return 'Diblokir';
      case PenggunaTab.persetujuan:
        return 'Persetujuan';
      case PenggunaTab.dormant:
        return 'Dormant';
    }
  }
}

/// Moderation → Pengguna sub-page.
///
/// Empat tab internal: Aktif · Diblokir · Persetujuan · Dormant.
/// Search bar membaca dari `penggunaSearchQueryProvider` sehingga perubahan
/// ter-reaktif di semua tab list (tidak perlu pass-down lewat state).
class AdminPenggunaScreen extends ConsumerStatefulWidget {
  const AdminPenggunaScreen({super.key});

  @override
  ConsumerState<AdminPenggunaScreen> createState() =>
      _AdminPenggunaScreenState();
}

class _AdminPenggunaScreenState extends ConsumerState<AdminPenggunaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PenggunaTab.values.length,
      vsync: this,
    );
    _searchController = TextEditingController(
      text: ref.read(penggunaSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(penggunaSearchQueryProvider);

    return Column(
      children: [
        // Search bar (writes to provider → list rebuilds reactively)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) {
              ref.read(penggunaSearchQueryProvider.notifier).state = v
                  .trim()
                  .toLowerCase();
            },
            decoration: InputDecoration(
              hintText: 'Cari nama atau email...',
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
                        ref.read(penggunaSearchQueryProvider.notifier).state =
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
          tabs: [for (final t in PenggunaTab.values) Tab(text: t.label)],
        ),

        const Divider(height: 1),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UserListAktif(),
              _UserListDiblokir(),
              _UserListPersetujuan(),
              _UserListDormant(),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserListAktif extends ConsumerWidget {
  const _UserListAktif();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(activeUsersStreamProvider);
    final query = ref.watch(penggunaSearchQueryProvider);
    return _UserListScaffold(
      usersAsync: usersAsync,
      query: query,
      action: (user) => _BanButton(user: user),
      emptyMessage: 'Tidak ada pengguna aktif.',
    );
  }
}

class _UserListDiblokir extends ConsumerWidget {
  const _UserListDiblokir();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(bannedUsersStreamProvider);
    final query = ref.watch(penggunaSearchQueryProvider);
    return _UserListScaffold(
      usersAsync: usersAsync,
      query: query,
      action: (user) => _UnbanButton(user: user),
      emptyMessage: 'Tidak ada pengguna diblokir.',
    );
  }
}

class _UserListPersetujuan extends ConsumerWidget {
  const _UserListPersetujuan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(pendingOfficersStreamProvider);
    final query = ref.watch(penggunaSearchQueryProvider);

    // Bantu admin membedakan stage di list (kecil tapi penting —
    // lihat `streamPendingOfficers` untuk konteks).
    return _UserListScaffold(
      usersAsync: usersAsync,
      query: query,
      action: (user) => _ApprovalActions(user: user),
      emptyMessage: 'Tidak ada officer menunggu persetujuan.',
      extraInfo: (user) {
        if (user.status == 'pending_verification') {
          return _StageBadge(
            label: 'Belum verifikasi email',
            color: Colors.orange.shade700,
            icon: Icons.mark_email_unread_outlined,
            tooltip:
                'Officer ini belum klik link verifikasi di emailnya. '
                'Tidak bisa disetujui sampai verifikasi email selesai.',
          );
        }
        if (user.status == 'pending') {
          return _StageBadge(
            label: 'Siap disetujui',
            color: Colors.blue.shade700,
            icon: Icons.check_circle_outline,
            tooltip: 'Email terverifikasi, menunggu persetujuan admin.',
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _UserListDormant extends ConsumerWidget {
  const _UserListDormant();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(dormantUsersStreamProvider);
    final query = ref.watch(penggunaSearchQueryProvider);
    return _UserListScaffold(
      usersAsync: usersAsync,
      query: query,
      action: (user) => _ReactivateButton(user: user),
      emptyMessage: 'Tidak ada akun dormant.',
    );
  }
}

class _UserListScaffold extends StatelessWidget {
  const _UserListScaffold({
    required this.usersAsync,
    required this.query,
    required this.action,
    required this.emptyMessage,
  });

  final AsyncValue<List<UserEntity>> usersAsync;
  final String query;
  final Widget Function(UserEntity user) action;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      data: (users) {
        final filtered = users.where((u) {
          if (query.isEmpty) return true;
          return u.fullName.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _UserCard(user: filtered[i], actionWidget: action(filtered[i])),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.actionWidget});
  final UserEntity user;
  final Widget actionWidget;

  String _initials() {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == UserRole.officer ? 'Petugas' : 'Warga';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
                Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.email} • $roleLabel',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (user.banReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: ${user.banReason}',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }
}

// ============================================================
// Action Buttons
// ============================================================

class _BanButton extends ConsumerWidget {
  const _BanButton({required this.user});
  final UserEntity user;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Blokir Pengguna'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan pemblokiran *',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().length < 10) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Blokir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final admin = ref.read(currentUserProvider).valueOrNull;
    if (admin == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .ban(
            uid: user.uid,
            reason: reasonController.text.trim(),
            bannedBy: admin.uid,
          );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _onPressed(context, ref),
      icon: const Icon(Icons.block, size: 16),
      label: const Text('Ban'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade300),
      ),
    );
  }
}

class _UnbanButton extends ConsumerWidget {
  const _UnbanButton({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Buka Blokir'),
            content: Text('Buka blokir untuk ${user.fullName}?'),
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
          await ref.read(userRepositoryProvider).unban(user.uid);
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
      },
      icon: const Icon(Icons.lock_open, size: 16),
      label: const Text('Unban'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ApprovalActions extends ConsumerWidget {
  const _ApprovalActions({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            final admin = ref.read(currentUserProvider).valueOrNull;
            if (admin == null) return;
            try {
              await ref
                  .read(userRepositoryProvider)
                  .approveOfficer(uid: user.uid, approvedBy: admin.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Officer disetujui.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Setujui',
        ),
        IconButton(
          onPressed: () async {
            final reasonController = TextEditingController();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Tolak Pendaftaran'),
                content: TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alasan penolakan *',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (reasonController.text.trim().length < 10) return;
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Tolak'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            final admin = ref.read(currentUserProvider).valueOrNull;
            if (admin == null) return;
            try {
              await ref
                  .read(userRepositoryProvider)
                  .rejectOfficer(
                    uid: user.uid,
                    reason: reasonController.text.trim(),
                    bannedBy: admin.uid,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pendaftaran ditolak.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          },
          icon: const Icon(Icons.cancel, color: Colors.red),
          tooltip: 'Tolak',
        ),
      ],
    );
  }
}

class _ReactivateButton extends ConsumerWidget {
  const _ReactivateButton({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await ref.read(userRepositoryProvider).reactivate(user.uid);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Akun diaktifkan kembali.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
          }
        }
      },
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Reactivate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
