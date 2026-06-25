import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tipe notifikasi yang dipakai oleh seluruh role. Field `type` menentukan
/// ikon, warna, dan label filter chip yang ditampilkan.
enum NotificationType {
  laporanBaru(
    'laporan_baru',
    'Laporan Baru',
    Icons.add_circle_outline,
    AppColors.primary,
  ),
  statusBerubah(
    'status_berubah',
    'Status Berubah',
    Icons.swap_horiz,
    AppColors.accent,
  ),
  komentarBaru(
    'komentar_baru',
    'Komentar Baru',
    Icons.chat_bubble_outline,
    AppColors.success,
  ),
  penugasan(
    'penugasan',
    'Penugasan',
    Icons.assignment_outlined,
    AppColors.primaryDark,
  ),
  system('system', 'Sistem', Icons.info_outline, AppColors.textSecondary),
  banding('banding', 'Banding', Icons.gavel_outlined, AppColors.error),
  slaBreach(
    'sla_breach',
    'SLA Breach',
    Icons.timer_off_outlined,
    AppColors.error,
  );

  const NotificationType(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

/// Model notifikasi. Dipakai oleh semua role (admin, citizen, officer).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.reportId,
    this.officerId,
    this.userId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? reportId;
  final String? officerId;
  final String? userId;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      reportId: reportId,
      officerId: officerId,
      userId: userId,
    );
  }
}

/// Halaman notifikasi generik yang dipakai oleh ketiga role (admin, citizen,
/// officer). Daftar isi, filter, dan aksi disesuaikan lewat parameter
/// [availableTypes] dan [onNotificationTap] (deep-link callback).
///
/// Mock data dipakai di awal; integrasi Firestore tinggal mengganti
/// `_mockNotifications` dengan stream dari `/users/{uid}/notifications`.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.roleLabel,
    this.availableTypes,
    this.onNotificationTap,
    this.onLogout,
    this.onMarkAllRead,
  });

  /// Label role untuk header kosong dan title — e.g. "Admin", "Warga",
  /// "Petugas".
  final String roleLabel;

  /// Tipe notifikasi yang ditampilkan di filter chips. Null = tampilkan
  /// semua. Chip pertama "Semua" selalu ada.
  final List<NotificationType>? availableTypes;

  /// Deep-link callback saat user tap notifikasi. Menerima
  /// [AppNotification] dan harus return `true` jika navigasi dilakukan.
  final bool Function(AppNotification)? onNotificationTap;

  /// Logout callback — bila null, tombol logout tidak muncul.
  final VoidCallback? onLogout;

  /// Mark-all-read callback — bila null, tombol tidak muncul.
  final VoidCallback? onMarkAllRead;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<AppNotification> _notifications;
  NotificationType? _filter;

  @override
  void initState() {
    super.initState();
    _notifications = _seedMockNotifications();
  }

  List<AppNotification> _seedMockNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        type: NotificationType.laporanBaru,
        title: 'Laporan Baru Masuk',
        body: 'Lubang Jalan di Jl. Sudirman — dilaporkan oleh Warga A.',
        createdAt: now.subtract(const Duration(minutes: 5)),
        reportId: 'rep_001',
      ),
      AppNotification(
        id: 'n2',
        type: NotificationType.statusBerubah,
        title: 'Status Laporan Diperbarui',
        body: 'Laporan #rep_002 kini berstatus "In Progress".',
        createdAt: now.subtract(const Duration(hours: 1)),
        reportId: 'rep_002',
      ),
      AppNotification(
        id: 'n3',
        type: NotificationType.penugasan,
        title: 'Penugasan Baru',
        body: 'Anda ditugaskan untuk laporan #rep_003 di Kec. Sukolilo.',
        createdAt: now.subtract(const Duration(hours: 3)),
        reportId: 'rep_003',
      ),
      AppNotification(
        id: 'n4',
        type: NotificationType.komentarBaru,
        title: 'Komentar Baru',
        body: 'Admin menambahkan komentar pada laporan Anda.',
        createdAt: now.subtract(const Duration(hours: 6)),
        reportId: 'rep_001',
      ),
      AppNotification(
        id: 'n5',
        type: NotificationType.slaBreach,
        title: 'SLA Breach',
        body: 'Laporan #rep_004 sudah > 48 jam tanpa respons.',
        createdAt: now.subtract(const Duration(days: 1)),
        reportId: 'rep_004',
      ),
      AppNotification(
        id: 'n6',
        type: NotificationType.banding,
        title: 'Banding Baru Diajukan',
        body: 'Warga mengajukan banding untuk laporan yang ditolak.',
        createdAt: now.subtract(const Duration(days: 2)),
        reportId: 'rep_005',
      ),
      AppNotification(
        id: 'n7',
        type: NotificationType.system,
        title: 'Pemeliharaan Sistem',
        body: 'Sistem akan maintenance pada Minggu, 02:00 WIB.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> get _filtered {
    if (_filter == null) return _notifications;
    return _notifications.where((n) => n.type == _filter).toList();
  }

  void _onTapNotification(AppNotification n) {
    setState(() {
      _notifications = _notifications
          .map((e) => e.id == n.id ? e.copyWith(isRead: true) : e)
          .toList();
    });
    final navigated = widget.onNotificationTap?.call(n) ?? false;
    if (!navigated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi ditandai dibaca: ${n.title}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map((e) => e.copyWith(isRead: true))
          .toList();
    });
    widget.onMarkAllRead?.call();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 7).floor()} minggu lalu';
  }

  @override
  Widget build(BuildContext context) {
    final chips = widget.availableTypes ?? NotificationType.values;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifikasi — ${widget.roleLabel}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          // Bell badge (hiasan — halaman ini sendiri adalah isi bell)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                icon: const Icon(Icons.notifications),
                onPressed: null,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Logout (di AppBar sesuai spec "next to logout button")
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text(
                      'Apakah Anda yakin ingin keluar dari akun ini?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) widget.onLogout!.call();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips + mark-all-read row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _unreadCount > 0
                            ? '$_unreadCount belum dibaca'
                            : 'Semua sudah dibaca',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.onMarkAllRead != null && _unreadCount > 0)
                      TextButton(
                        onPressed: _markAllRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Tandai semua dibaca',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                        count: _notifications.length,
                      ),
                      const SizedBox(width: 6),
                      for (final t in chips) ...[
                        _FilterChip(
                          label: t.label,
                          selected: _filter == t,
                          color: t.color,
                          icon: t.icon,
                          onTap: () => setState(() => _filter = t),
                          count: _notifications
                              .where((n) => n.type == t)
                              .length,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(roleLabel: widget.roleLabel)
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (mounted) setState(() {});
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72, endIndent: 16),
                      itemBuilder: (context, i) {
                        final n = _filtered[i];
                        return _NotificationTile(
                          notification: n,
                          relativeTime: _relativeTime(n.createdAt),
                          onTap: () => _onTapNotification(n),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Chip filter dengan count badge kecil di sebelah kanan label.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
    this.count = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : (color ?? AppColors.textPrimary);
    final bg = selected ? (color ?? AppColors.primary) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? bg : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white24
                      : AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: fg,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.relativeTime,
    required this.onTap,
  });

  final AppNotification notification;
  final String relativeTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? Colors.white : AppColors.primarySoft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon type
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: n.type.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(n.type.icon, color: n.type.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!n.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Notifikasi untuk akun $roleLabel akan muncul di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
