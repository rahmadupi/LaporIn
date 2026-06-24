# User Login & Role Resolution

## 1. Overview

The Login module authenticates existing users. It acts as the gateway that identifies the user and triggers the Riverpod providers to fetch their role, dictating which isolated app workspace they are allowed to enter.

## 2. UI/UX Requirements

- **Input Fields:** Email Address, Password.
- **Actions:** "Login" button, "Forgot Password?" text button, "Don't have an account? Register" text button.
- **Loading State:** The login button must display a progress indicator during the network request to prevent double-tapping.

## 3. Database Interactions (Data Layer)

- **Action 1 (Auth):** Call `FirebaseAuth.instance.signInWithEmailAndPassword()`.
- **Action 2 (Firestore):** Await the read operation from `/users/{uid}` to resolve the user's role before clearing the loading state.

## 4. Acceptance Criteria

- **Scenario 1: Admin Login Routing**
  - **Given** a user inputs credentials for an account where the Firestore document has `role: "admin"`.
  - **When** the login is successful.
  - **Then** `GoRouter` redirects the user to `/admin_dashboard`.
- **Scenario 2: Invalid Credentials**
  - **Given** a user inputs an incorrect password.
  - **When** the login is submitted.
  - **Then** the UI stops loading and displays a "Invalid email or password" error banner.

---

## 5. Login Provider (Riverpod)

```dart
// filepath: app/lib/landing/auth/login/login_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/domain_data/auth/domain/auth_provider.dart';
import '../../shared/domain_data/auth/data/auth_repository.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.initial, this.errorMessage});

  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginNotifier(this._ref) : super(const LoginState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: LoginStatus.loading, errorMessage: null);

    try {
      final auth = _ref.read(firebaseAuthProvider);
      final repository = _ref.read(authRepositoryProvider);

      await auth.signInWithEmailAndPassword(email: email, password: password);

      final user = auth.currentUser;
      if (user == null) {
        state = state.copyWith(status: LoginStatus.error, errorMessage: 'User not found');
        return false;
      }

      final userEntity = await repository.getUserById(user.uid);

      // Check if officer is pending approval
      if (userEntity?.role == 'officer' && userEntity?.status == 'pending') {
        await auth.signOut();
        state = state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Akun Anda masih menunggu persetujuan Admin.',
        );
        return false;
      }

      // Check if banned
      if (userEntity?.status == 'banned') {
        await auth.signOut();
        state = state.copyWith(
          status: LoginStatus.error,
          errorMessage: 'Akun Anda telah diblokir. Hubungi Admin.',
        );
        return false;
      }

      state = state.copyWith(status: LoginStatus.success);
      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Email atau password salah';
      } else {
        message = 'Terjadi kesalahan. Silakan coba lagi.';
      }
      state = state.copyWith(status: LoginStatus.error, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      return false;
    }
  }

  void reset() {
    state = const LoginState();
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});
```

---

## 6. Login Screen Implementation

```dart
// filepath: app/lib/landing/auth/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/widgets/lap_button.dart';
import '../../../shared/ui/widgets/lap_text_field.dart';
import '../../../core/constants/app_colors.dart';
import 'login_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password harus diisi')),
      );
      return;
    }

    await ref.read(loginProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.status == LoginStatus.error && next.errorMessage != null) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.report_problem,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'LaporIn',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              LapTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              LapTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Lupa password?'),
                ),
              ),
              const SizedBox(height: 24),
              LapButton(
                onPressed: loginState.status == LoginStatus.loading
                    ? null
                    : _handleLogin,
                isLoading: loginState.status == LoginStatus.loading,
                child: const Text('Masuk'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? '),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
