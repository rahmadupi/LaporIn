# Password Recovery (Lupa Password)

> **Lokasi di Aplikasi:** Terintegrasi di halaman **Login** (tautan "Lupa password?") dan juga tersedia di menu **User Profile Management** (untuk admin yang sudah login dan ingin mereset password mereka).

## 1. Overview

Allows users who have lost access to their accounts to initiate a secure password reset flow via their registered email address.

## 2. UI/UX Requirements

- **Input Field:** Email Address.
- **Action:** "Send Reset Link" button.
- **Success State:** A visual confirmation (e.g., a green checkmark or dialog) instructing the user to check their inbox, along with a "Back to Login" button.

## 3. Database Interactions (Data Layer)

- **Action (Auth):** Call `FirebaseAuth.instance.sendPasswordResetEmail(email: inputEmail)`.
- **Note:** This action does not touch Firestore.

## 4. Acceptance Criteria

- **Scenario 1: Valid Email Reset**
  - **Given** a user inputs an email address that exists in the Firebase Auth system.
  - **When** they request a reset link.
  - **Then** Firebase triggers a password reset email.
  - **And** the UI shows a success message.
- **Scenario 2: Unregistered Email**
  - **Given** a user inputs an email not registered in the system.
  - **When** they request a reset link.
  - **Then** the UI shows an error stating "No account found with this email." (Or, depending on security preference to prevent email enumeration, displays the standard success message regardless).

---

## 5. Forgot Password Provider (Riverpod)

```dart
// filepath: app/lib/landing/auth/forgot_password/forgot_password_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/domain_data/auth/domain/auth_provider.dart';

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;

  ForgotPasswordNotifier(this._ref) : super(const ForgotPasswordState());

  Future<bool> sendResetLink(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null);

    try {
      final auth = _ref.read(firebaseAuthProvider);
      await auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(status: ForgotPasswordStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'Tidak ada akun dengan email ini';
      } else {
        message = 'Terjadi kesalahan. Silakan coba lagi.';
      }
      state = state.copyWith(status: ForgotPasswordStatus.error, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      return false;
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider = StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>((ref) {
  return ForgotPasswordNotifier(ref);
});
```

---

## 6. Forgot Password Screen Implementation

```dart
// filepath: app/lib/landing/auth/forgot_password/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/widgets/lap_button.dart';
import '../../../shared/ui/widgets/lap_text_field.dart';
import '../../../core/constants/app_colors.dart';
import 'forgot_password_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email harus diisi')),
      );
      return;
    }

    final success = await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetLink(email);

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Link Terkirim'),
          ],
        ),
        content: const Text(
          'Silakan periksa email Anda untuk reset password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Kembali ke Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (previous, next) {
      if (next.status == ForgotPasswordStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan email Anda dan kami akan mengirimkan link untuk reset password.',
                style: TextStyle(fontSize: 14, color: AppColors.neutral600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LapTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              LapButton(
                onPressed: state.status == ForgotPasswordStatus.loading
                    ? null
                    : _handleReset,
                isLoading: state.status == ForgotPasswordStatus.loading,
                child: const Text('Kirim Link Reset'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
