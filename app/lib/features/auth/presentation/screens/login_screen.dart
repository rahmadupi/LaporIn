import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../auth_navigator.dart';
import '../providers/auth_provider.dart';

/// Login Screen (S2) — email/password dengan role-based routing (FR-1.2).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey<FormState> dipakai untuk memicu validasi seluruh field sekaligus.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State lokal untuk toggle visibility password (ikon mata pada mockup).
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Controller wajib di-dispose untuk mencegah memory leak.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handler tombol "Masuk": validasi -> panggil provider -> navigasi/eror.
  Future<void> _onLoginPressed() async {
    // Jalankan validator semua field; berhenti bila ada yang tidak valid.
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return; // Cek mounted karena ada gap async di atas.

    if (success) {
      // Arahkan ke home sesuai role hasil custom claims (role-based routing).
      final route = AuthNavigator.homeRouteFor(auth.user!.role);
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      // Tampilkan pesan kegagalan yang sudah diterjemahkan oleh provider.
      SnackbarHelper.showError(
          context, auth.errorMessage ?? 'Gagal masuk.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch agar tombol bereaksi terhadap perubahan state loading.
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                  // Logo outline lingkaran di atas, sesuai mockup.
                  Center(
                    child: Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Icon(Icons.campaign_outlined,
                          color: AppColors.textSecondary, size: 30),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang Kembali',
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
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                    // Ikon mata untuk show/hide password.
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
                  // Link "Lupa password?" rata kanan menuju Forgot Password.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.forgotPassword),
                      child: const Text('Lupa password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Masuk',
                    isLoading: isLoading,
                    onPressed: _onLoginPressed,
                  ),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 20),
                  _buildGoogleButton(),
                  const SizedBox(height: 32),
                  // Footer menuju Register.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.register),
                        child: const Text('Daftar',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
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

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('atau masuk dengan',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  /// Tombol Google ditampilkan sesuai mockup, tetapi sengaja DINONAKTIFKAN
  /// (onPressed null) — fokus branch ini email/password (FR-1.1). Implementasi
  /// google_sign_in dapat ditambahkan menyusul tanpa mengubah layout.
  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: null, // Placeholder: belum aktif.
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.border),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Lanjutkan dengan Google'),
    );
  }
}
