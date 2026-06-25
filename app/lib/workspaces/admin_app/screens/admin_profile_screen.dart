import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

/// Halaman Profil Admin.
///
/// Sesuai instruksi profile page sederhana:
///   - Top bar: nama user (tanpa foto profil)
///   - Toggle notifikasi HP (FCM push on/off)
///   - Tombol Ubah Password (alur sama dengan forgot password)
///   - Tombol Hapus Akun (konfirmasi typed "HAPUS")
///
/// UI file independen per role (redundant by design — agar tiap workspace
/// punya widget yang berdiri sendiri tanpa coupling).
class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isLoading = false;

  Future<void> _toggleNotification(bool enabled) async {
    setState(() => _isLoading = true);
    try {
      // Toggle on -> null = nonaktifkan push (user hanya melihat via bell).
      // Toggle off -> minta token baru (placeholder string di sini; real
      // implementation akan ambil dari FirebaseMessaging.instance.getToken()).
      final repo = ref.read(authRepositoryProvider);
      if (enabled) {
        // Placeholder: pada production, ganti dengan token asli dari
        // FirebaseMessaging. Disimpan string kosong agar toggle UI
        // berfungsi walau Firebase Messaging belum diinisialisasi.
        await repo.updateFcmToken('placeholder_token_${DateTime.now().millisecondsSinceEpoch}');
      } else {
        await repo.updateFcmToken(null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'Notifikasi HP diaktifkan — push akan diterima di luar aplikasi.'
              : 'Notifikasi HP dimatikan — notifikasi hanya tersedia di dalam aplikasi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui preferensi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword(String email) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Email Reset Terkirim'),
          content: Text(
              'Link untuk mengubah password telah dikirim ke $email. Silakan cek inbox Anda.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim email reset: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan ini tidak dapat dibatalkan. Akun, data profil, dan '
              'semua laporan yang terkait akan dihapus permanen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ketik "HAPUS" (huruf besar) untuk konfirmasi:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'HAPUS',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim() == 'HAPUS'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      await ref.read(currentUserProvider.notifier).refresh();
      if (!mounted) return;
      context.go(AppRoutes.splash);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus akun: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isNotifOn = user?.fcmToken != null && user!.fcmToken!.isNotEmpty;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // === TOP BAR: Profile details (nama saja, tanpa foto) ===
            _ProfileHeader(name: user?.fullName ?? 'Admin'),
            const SizedBox(height: 24),

            // === Notification toggle ===
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: SwitchListTile(
                value: isNotifOn,
                onChanged: _isLoading ? null : _toggleNotification,
                title: const Text(
                  'Notifikasi HP (Push)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isNotifOn
                      ? 'Aktif — push diterima di luar aplikasi.'
                      : 'Nonaktif — notifikasi hanya di dalam aplikasi (lewat ikon bel).',
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: Icon(
                  isNotifOn
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: isNotifOn ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Change Password button ===
            _ActionTile(
              icon: Icons.lock_outline,
              iconColor: AppColors.primary,
              title: 'Ubah Password',
              subtitle: 'Kirim link reset ke email Anda.',
              onTap: _isLoading || user == null
                  ? null
                  : () => _changePassword(user.email),
            ),
            const SizedBox(height: 12),

            // === Delete Account button ===
            _ActionTile(
              icon: Icons.delete_outline,
              iconColor: AppColors.error,
              title: 'Hapus Akun',
              subtitle: 'Tindakan ini permanen dan tidak dapat dibatalkan.',
              titleColor: AppColors.error,
              onTap: _isLoading ? null : _deleteAccount,
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Inisial nama di tengah sebagai placeholder (bukan foto profil).
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}