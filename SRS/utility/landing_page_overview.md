SplashScreen# Landing Page & Router Gatekeeper Overview

## 1. Overview

The Landing Page serves as the unified entry point for the LaporIn application. It is not just a UI screen, but the core **Router Gatekeeper**. Its primary responsibility is to intercept the user, verify their authentication status via Firebase, read their specific `role` from Firestore, and strictly route them to their isolated workspace (Citizen App, Admin App, or Officer App).

## 2. Architectural Role (App-Within-An-App)

- **Centralized Auth:** Users from all three roles use the same login interface.
- **Decentralized Workspaces:** Once authenticated, the router permanently locks the user into their role-specific `lib/workspaces/` directory. An Admin cannot navigate to Citizen screens, and vice versa.

## 3. UI/UX Requirements

- **Splash Screen:** A minimal loading screen displaying the LaporIn logo while the `GoRouter` and Riverpod `StreamProvider` evaluate the current Firebase Auth session.
- **Onboarding (Optional):** A brief carousel explaining the app's purpose for first-time Citizen users.
- **Unified Gateway:** A clean interface with prominent "Login" and "Register" buttons.

## 4. Routing Logic (GoRouter + Riverpod)

- **Unauthenticated State:** If `FirebaseAuth.instance.currentUser` is null, lock navigation to `/login` or `/register`.
- **Authenticated State:**
  1. Fetch `/users/{uid}` from Firestore.
  2. Read the `role` field.
  3. Execute `context.go('/citizen_dashboard')`, `context.go('/admin_dashboard')`, or `context.go('/officer_dashboard')` based strictly on the role.

---

## 5. Project Structure

```
app/lib/
├── main.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   ├── errors/
│   │   └── failures.dart
│   └── routing/
│       └── app_router.dart
├── shared/
│   ├── domain_data/
│   │   └── auth/
│   │       ├── data/
│   │       │   ├── user_model.dart
│   │       │   └── auth_repository.dart
│   │       └── domain/
│   │           ├── auth_provider.dart
│   │           └── user_provider.dart
│   ├── ui/
│   │   └── widgets/
│   │       ├── lap_button.dart
│   │       ├── lap_text_field.dart
│   │       ├── lap_card.dart
│   │       └── loading_overlay.dart
│   └── services/
│       └── notification_service.dart
└── landing/
    ├── splash/
    │   └── splash_screen.dart
    ├── auth/
    │   ├── login/
    │   │   ├── login_screen.dart
    │   │   └── login_provider.dart
    │   ├── register/
    │   │   ├── register_screen.dart
    │   │   └── register_provider.dart
    │   └── forgot_password/
    │       ├── forgot_password_screen.dart
    │       └── forgot_password_provider.dart
    └── notification/
        ├── notification_detail_screen.dart
        └── notification_provider.dart
```

---

## 6. Splash Screen Implementation

```dart
// filepath: app/lib/landing/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/domain_data/auth/domain/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.report_problem,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LaporIn',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );

    // Navigate based on auth state
    authState.when(
      data: (user) {
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final currentUser = ref.read(currentUserProvider);
            currentUser.when(
              data: (userEntity) {
                if (userEntity != null) {
                  switch (userEntity.role) {
                    case 'admin':
                      context.go('/admin');
                      break;
                    case 'officer':
                      context.go('/officer');
                      break;
                    default:
                      context.go('/citizen');
                  }
                } else {
                  context.go('/login');
                }
              },
              loading: () {},
              error: (_, __) => context.go('/login'),
            );
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
        }
      },
      loading: () {},
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
      },
    );
  }
}
```
