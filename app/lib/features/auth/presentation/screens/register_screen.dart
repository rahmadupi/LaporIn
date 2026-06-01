import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/user_role.dart';
import '../auth_navigator.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_selector_card.dart';

/// Register Screen (S3) — registrasi akun baru dengan pemilihan role (FR-1.1).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Role default = citizen (Warga), sesuai kartu yang ter-highlight di mockup.
  UserRole _selectedRole = UserRole.citizen;

  // Checkbox persetujuan S&K; tombol Daftar baru aktif bila ini true.
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

  /// Handler tombol "Daftar": validasi -> register -> navigasi sesuai role.
  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;

    // Pastikan user sudah menyetujui S&K sebelum lanjut.
    if (!_agreedToTerms) {
      SnackbarHelper.showError(
          context, 'Anda harus menyetujui Syarat & Ketentuan.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text,
      email: _emailController.text,
      // Simpan nomor dalam format internasional +62 sesuai skema users.
      phoneNumber: '+62${_phoneController.text.trim()}',
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(context, 'Pendaftaran berhasil!');
      final route = AuthNavigator.homeRouteFor(auth.user!.role);
      // pushNamedAndRemoveUntil membersihkan stack agar tidak bisa "back"
      // kembali ke form register setelah berhasil masuk.
      Navigator.of(context)
          .pushNamedAndRemoveUntil(route, (route) => false);
    } else {
      SnackbarHelper.showError(
          context, auth.errorMessage ?? 'Gagal mendaftar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        // Tombol back kembali ke Login.
        leading: const BackButton(color: AppColors.textPrimary),
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
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  // Validator membandingkan dengan password utama.
                  validator: (v) => Validators.confirmPassword(
                      v, _passwordController.text),
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
                const SizedBox(height: 24),
                const Text(
                  'Daftar sebagai:',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                // Dua kartu pilihan role bersebelahan (Warga / Petugas).
                Row(
                  children: [
                    Expanded(
                      child: RoleSelectorCard(
                        icon: Icons.person,
                        title: 'Warga',
                        isSelected: _selectedRole == UserRole.citizen,
                        onTap: () => setState(
                            () => _selectedRole = UserRole.citizen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RoleSelectorCard(
                        icon: Icons.engineering,
                        title: 'Petugas',
                        subtitle: 'Memerlukan verifikasi admin',
                        isSelected: _selectedRole == UserRole.officer,
                        onTap: () => setState(
                            () => _selectedRole = UserRole.officer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTermsCheckbox(),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Daftar',
                  isLoading: isLoading,
                  onPressed: _onRegisterPressed,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      // pop kembali ke Login (Register dibuka via push dari Login).
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text('Masuk',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              children: [
                TextSpan(text: 'Saya menyetujui '),
                TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: TextStyle(color: AppColors.primary)),
                TextSpan(text: ' dan '),
                TextSpan(
                    text: 'Kebijakan Privasi',
                    style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
