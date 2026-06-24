import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Forgot Password Screen — mengirim email reset password via Firebase.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Handler "Kirim Link Reset": validasi email -> minta Firebase kirim email.
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(_emailController.text);

    if (!mounted) return;

    if (success) {
      SnackbarHelper.showSuccess(
        context,
        'Link reset password telah dikirim ke email Anda.',
      );
      // Kembali ke Login setelah email terkirim.
      Navigator.of(context).pop();
    } else {
      SnackbarHelper.showError(
          context, auth.errorMessage ?? 'Gagal mengirim email reset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                // Ikon kunci sebagai ilustrasi konteks "reset password".
                Center(
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset,
                        color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Lupa Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan email terdaftar Anda. Kami akan mengirim link untuk '
                  'mengatur ulang password.',
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
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Kirim Link Reset',
                  isLoading: isLoading,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
