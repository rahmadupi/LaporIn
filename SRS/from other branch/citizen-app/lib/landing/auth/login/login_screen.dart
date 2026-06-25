import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../core/auth/auth_navigator.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import 'login_provider.dart';

/// Login Screen (S2) — email/password dengan role-based routing.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(loginProvider.notifier)
        .login(_emailController.text, _passwordController.text);
  }

  Future<void> _onReactivatePressed() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(loginProvider.notifier)
        .reactivateAndSignIn(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.status == LoginStatus.error && next.errorMessage != null) {
        // Untuk akun yang diblokir, tampilkan kartu khusus di atas form
        // (bukan snackbar) supaya pesan pemblokiran lebih prominent.
        if (next.isBanned) {
          return;
        }
        // Untuk akun dormant, tampilkan kartu dormant dengan tombol re-activate
        if (next.isInactive) {
          return;
        }
        // Untuk pending officer, tampilkan banner non-intrusive (bukan snackbar)
        if (next.errorCode == AuthErrorCode.pendingOfficer) {
          return;
        }
        SnackbarHelper.showError(context, next.errorMessage!);
      }
      if (next.status == LoginStatus.success) {
        // Navigasi eksplisit ke workspace sesuai role setelah login berhasil
        final currentUser = ref.read(currentUserProvider).valueOrNull;
        if (currentUser != null && mounted) {
          final route = AuthNavigator.homeRouteFor(currentUser.role);
          context.go(route);
        }
      }
    });

    // Card/kartu khusus untuk akun yang diblokir - tampil di atas form.
    final bannedCard = loginState.isBanned
        ? _BannedAccountCard(
            reason: loginState.banReason,
            bannedAt: loginState.bannedAt,
          )
        : null;

    // Card untuk akun dormant (inActive) - tampil di atas form dengan
    // tombol "Aktifkan Kembali". User dapat self re-activate.
    final dormantCard = loginState.isInactive
        ? _DormantAccountCard(
            message: loginState.errorMessage,
            isLoading: loginState.isReactivating,
            onReactivate: _onReactivatePressed,
          )
        : null;

    // Banner non-intrusive untuk officer yang masih menunggu approval.
    final pendingBanner = loginState.errorCode == AuthErrorCode.pendingOfficer
        ? _PendingOfficerBanner(message: loginState.errorMessage ?? '')
        : null;

    // Untuk akun yang diblokir, hanya blokir "Masuk" dan "Lupa password?".
    // Form fields (email/password), tombol "Daftar", dan fungsi lain tetap
    // aktif agar UI bersifat informasi saja (user masih bisa register
    // akun baru dengan email berbeda, atau sekadar membaca informasinya).
    final loginBlocked = loginState.isBanned;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  if (bannedCard != null) ...[
                    bannedCard,
                    const SizedBox(height: 24),
                  ] else if (dormantCard != null) ...[
                    dormantCard,
                    const SizedBox(height: 24),
                  ] else if (pendingBanner != null) ...[
                    pendingBanner,
                    const SizedBox(height: 24),
                  ],
                  Center(
                    child: Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: AppColors.textSecondary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk untuk mulai melapor atau melanjutkan tugas Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Email',
                    hint: 'nama@email.com',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      // Lupa password tetap diblokir untuk akun banned - tidak
                      // ada gunanya reset password kalau user tetap tidak bisa login.
                      onPressed: loginBlocked
                          ? null
                          : () => context.push(AppRoutes.forgotPassword),
                      child: const Text('Lupa password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Masuk',
                    isLoading: loginState.status == LoginStatus.loading,
                    // Tombol Masuk diblokir untuk akun banned (informasi saja).
                    onPressed: loginBlocked ? null : _onLoginPressed,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu merah yang menampilkan alasan pemblokiran akun.
///
/// Ditampilkan di atas form login ketika [LoginState.isBanned] true.
/// Bersifat **informasi saja** — form input (email/password) tetap aktif,
/// tombol "Daftar" tetap aktif, hanya tombol "Masuk" dan "Lupa password?"
/// yang dinonaktifkan.
class _BannedAccountCard extends StatelessWidget {
  const _BannedAccountCard({this.reason, this.bannedAt});

  final String? reason;
  final DateTime? bannedAt;

  @override
  Widget build(BuildContext context) {
    final hasReason = reason != null && reason!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, color: AppColors.error, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Akun Diblokir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Akun dengan email ini tidak dapat digunakan untuk masuk. '
            'Hubungi Admin untuk informasi lebih lanjut, atau daftar '
            'akun baru dengan email yang berbeda.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (hasReason) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alasan pemblokiran:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (bannedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Diblokir pada: ${_formatDate(bannedAt!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final d = dt.toLocal();
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Banner kuning yang menampilkan status pending officer.
class _PendingOfficerBanner extends StatelessWidget {
  const _PendingOfficerBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menunggu Persetujuan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
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

/// Kartu biru/informational untuk akun dormant (`status == "inActive"`).
///
/// Berbeda dari [_BannedAccountCard] (merah/permanen) dan
/// [_PendingOfficerBanner] (kuning/sementara), kartu ini menggunakan
/// tone biru/netral karena dormant BUKAN sanksi - akun hanya auto-flagged
/// oleh sistem. User dapat self re-activate lewat tombol "Aktifkan Kembali".
class _DormantAccountCard extends StatelessWidget {
  const _DormantAccountCard({
    this.message,
    required this.isLoading,
    required this.onReactivate,
  });

  final String? message;
  final bool isLoading;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF1E88E5), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Akun Tidak Aktif',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message ??
                'Akun Anda saat ini dalam status tidak aktif karena sudah lama tidak digunakan.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data dan laporan Anda tetap tersimpan dengan aman. '
            'Aktifkan kembali untuk melanjutkan.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onReactivate,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(isLoading ? 'Mengaktifkan...' : 'Aktifkan Kembali'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
