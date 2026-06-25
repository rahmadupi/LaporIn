import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets auth/role_selector_card.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared_domain_data/auth/entities/user_role.dart';
import 'register_provider.dart';

/// Register Screen (S3) — registrasi akun baru dengan pemilihan role.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.citizen;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      SnackbarHelper.showError(
        context,
        'Anda harus menyetujui Syarat & Ketentuan.',
      );
      return;
    }

    final success = await ref
        .read(registerProvider.notifier)
        .register(
          fullName: _nameController.text,
          email: _emailController.text,
          phoneNumber: '+62${_phoneController.text.trim()}',
          password: _passwordController.text,
          role: _selectedRole,
        );

    if (!mounted) return;

    if (success) {
      final state = ref.read(registerProvider);
      if (state.officerPendingApproval) {
        _showOfficerPendingDialog();
      } else {
        // Tampilkan dialog verifikasi email untuk semua role (selain officer pending)
        _showEmailVerificationDialog();
      }
    }
  }

  void _showOfficerPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.engineering, color: Colors.orange, size: 48),
        title: const Text('Pendaftaran Berhasil'),
        content: const Text(
          'Akun Petugas Anda sedang menunggu persetujuan Admin. '
          'Silakan cek email Anda untuk verifikasi, lalu tunggu admin '
          'menyetujui akun Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.go(AppRoutes.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.mark_email_read, color: Colors.green, size: 48),
        title: const Text('Verifikasi Email Anda'),
        content: const Text(
          'Kami telah mengirim link verifikasi ke email Anda.\n\n'
          'Silakan cek inbox (atau folder spam) dan klik link tersebut '
          'untuk mengaktifkan akun sebelum login.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.go(AppRoutes.login);
            },
            child: const Text('OK, Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    ref.listen<RegisterState>(registerProvider, (previous, next) {
      if (next.status == RegisterStatus.error && next.errorMessage != null) {
        SnackbarHelper.showError(context, next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bergabunglah untuk berkontribusi pada kotamu',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Pilihan Role
                Row(
                  children: [
                    Expanded(
                      child: RoleSelectorCard(
                        icon: Icons.person,
                        title: 'Warga',
                        subtitle: 'Aktif langsung',
                        isSelected: _selectedRole == UserRole.citizen,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.citizen),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RoleSelectorCard(
                        icon: Icons.engineering,
                        title: 'Petugas',
                        subtitle: 'Butuh persetujuan',
                        isSelected: _selectedRole == UserRole.officer,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.officer),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RoleSelectorCard(
                        icon: Icons.admin_panel_settings,
                        title: 'Admin',
                        subtitle: 'Demo only',
                        isSelected: _selectedRole == UserRole.admin,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.admin),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Nama'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nomor HP',
                  hint: '812xxxxxxx',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Minimal 8 karakter',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  controller: _confirmController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passwordController.text),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Daftar',
                  isLoading: registerState.status == RegisterStatus.loading,
                  onPressed: _agreedToTerms ? _onRegisterPressed : null,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
