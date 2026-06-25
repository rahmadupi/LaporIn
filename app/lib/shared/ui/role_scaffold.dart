import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laporin/core/theme/app_colors.dart';

/// Scaffold generik dengan BottomNavigationBar + AppBar actions untuk role-based app.
class RoleScaffold extends StatefulWidget {
  const RoleScaffold({
    super.key,
    required this.title,
    required this.tabs,
    required this.userName,
    required this.userRole,
    this.onLogout,
    this.notificationRoute,
  });

  /// Judul halaman (mis. "LaporIn - Admin").
  final String title;

  /// Daftar tab bottom navigation.
  final List<RoleTab> tabs;

  /// Nama user (ditampilkan di header).
  final String userName;

  /// Role user (citizen/officer/admin).
  final String userRole;

  /// Callback untuk logout button di AppBar.
  final VoidCallback? onLogout;

  /// Path tujuan ketika user tap bell icon di AppBar. Null = bell button
  /// tidak ditampilkan. Biasanya diisi dengan `AppRoutes.<role>Notifications`.
  final String? notificationRoute;

  @override
  State<RoleScaffold> createState() => RoleScaffoldState();
}

class RoleScaffoldState extends State<RoleScaffold> {
  int _currentIndex = 0;

  /// Switch ke tab pertama (untuk BackPressHandler).
  void switchToFirstTab() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  /// Getter untuk cek apakah di tab pertama.
  bool get isOnFirstTab => _currentIndex == 0;

  @override
  Widget build(BuildContext context) {
    final currentTab = widget.tabs[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Font lebih tebal & ukuran lebih besar untuk title AppBar
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        // Hilangkan tombol back otomatis - kita handle sendiri via PopScope
        automaticallyImplyLeading: false,
        actions: [
          if (widget.notificationRoute != null)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifikasi',
              onPressed: () {
                context.push(widget.notificationRoute!);
              },
            ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
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
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  widget.onLogout!();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Greeting bar (hanya tampil di tab pertama)
            if (_currentIndex == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   'SELAMAT DATANG,',
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.grey.shade500,
                    //     letterSpacing: 1.2,
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userName.isNotEmpty
                          ? widget.userName
                          : widget.userRole,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Role: ${widget.userRole}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            // Content tab aktif
            Expanded(child: currentTab.body),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade500,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (i) => setState(() => _currentIndex = i),
        items: widget.tabs
            .map(
              (t) =>
                  BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
            )
            .toList(),
      ),
    );
  }
}

/// Model untuk tab bottom navigation.
class RoleTab {
  final String label;
  final IconData icon;
  final Widget body;

  const RoleTab({required this.label, required this.icon, required this.body});
}
