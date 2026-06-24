# Authentication & Session Management

## 1. Overview

This module governs how the user's active session is maintained securely across app restarts. It leverages Firebase Authentication's native token management and Riverpod to provide a reactive state that the router listens to.

## 2. State Management Strategy (Riverpod)

- **`authStateProvider`:** A `StreamProvider` listening to `FirebaseAuth.instance.authStateChanges()`.
- **`currentUserProvider`:** An `AsyncNotifier` that reacts to the `authStateProvider`. If a user is logged in, it fetches their full `UserEntity` (including their role) from the `/users` Firestore collection and holds it in memory.

## 3. Security Rules

- **Token Refresh:** Handled automatically by the Firebase Auth SDK. No custom token rotation logic is required in the Flutter client.
- **Account Deactivation:** If an Admin sets a user's `status` to `"banned"` in Firestore, a Cloud Function must revoke their refresh tokens. The `authStateChanges()` stream will detect this and immediately push the user back to the `/login` route.
- **Pending Officer Gate:** If `status` is `"pending"` (officer awaiting approval), the client must block access to the officer workspace and show an "awaiting approval" message even though `authStateChanges()` reports a valid session.

## 4. Acceptance Criteria

- **Scenario 1: App Restart persistence**
  - **Given** a user is logged into the app.
  - **When** the user force-closes the app and reopens it.
  - **Then** the app bypasses the login screen and routes them directly to their role workspace without requiring credentials again.
- **Scenario 2: Forced Logout (Banned User)**
  - **Given** an active Citizen user has their account disabled by an Admin.
  - **When** the backend token revocation triggers.
  - **Then** Riverpod detects the null session and `GoRouter` instantly redirects the user to the Login screen.

---

## 5. Auth Providers (Riverpod)

```dart
// filepath: app/lib/shared/domain_data/auth/domain/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Auth state changes stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user provider (fetches full UserEntity from Firestore)
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, UserEntity?>(() {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) async {
        if (user == null) return null;
        final repository = ref.read(authRepositoryProvider);
        return repository.getUserById(user.uid);
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
```

---

## 6. Notification Provider (Riverpod)

```dart
// filepath: app/lib/landing/notification/notification_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> dataPayload;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.dataPayload,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      dataPayload: data['dataPayload'] ?? {},
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      dataPayload: dataPayload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationDetailNotifier extends AsyncNotifier<NotificationModel?> {
  @override
  Future<NotificationModel?> build() async {
    final notificationId = ref.watch(notificationIdProvider);
    if (notificationId == null) return null;

    final userId = ref.watch(userIdProvider);
    if (userId == null) return null;

    final db = FirebaseFirestore.instance;
    final doc = await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .get();

    if (!doc.exists) return null;

    final notification = NotificationModel.fromFirestore(doc);

    if (!notification.isRead) {
      await doc.reference.update({'isRead': true});
      return notification.copyWith(isRead: true);
    }

    return notification;
  }

  Future<void> markAsRead() async {
    final notification = state.valueOrNull;
    if (notification == null || notification.isRead) return;

    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    final db = FirebaseFirestore.instance;
    await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notification.id)
        .update({'isRead': true});

    state = AsyncData(notification.copyWith(isRead: true));
  }
}

final notificationDetailProvider = AsyncNotifierProvider<NotificationDetailNotifier, NotificationModel?>(() {
  return NotificationDetailNotifier();
});

final notificationIdProvider = StateProvider<String?>((ref) => null);
final userIdProvider = StateProvider<String?>((ref) => null);
```

---

## 7. Notification Detail Screen Implementation

```dart
// filepath: app/lib/landing/notification/notification_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/ui/widgets/lap_button.dart';
import '../../core/constants/app_colors.dart';
import 'notification_provider.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;
  final String userId;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    required this.userId,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationIdProvider.notifier).state = widget.notificationId;
      ref.read(userIdProvider.notifier).state = widget.userId;
    });
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'new_report': return '📋';
      case 'status_update': return '🔄';
      case 'dispatch_assigned': return '👷';
      case 'dispatch_completed': return '✅';
      case 'sla_breach': return '⚠️';
      case 'appeal_submitted': return '📝';
      case 'comment_reply': return '💬';
      default: return '🔔';
    }
  }

  String _getNotificationAction(String type) {
    switch (type) {
      case 'new_report': return 'Lihat Laporan';
      case 'status_update': return 'Lihat Status';
      case 'dispatch_assigned': return 'Lihat Tugas';
      case 'dispatch_completed': return 'Lihat Hasil';
      case 'sla_breach': return 'Tindakan Admin';
      case 'appeal_submitted': return 'Proses Banding';
      case 'comment_reply': return 'Lihat Komentar';
      default: return 'Lihat Detail';
    }
  }

  void _navigateToRelatedPage(NotificationModel notification) {
    final reportId = notification.dataPayload['reportId'];
    if (reportId == null) return;

    final role = ref.read(currentUserProvider).valueOrNull?.role;
    switch (role) {
      case 'admin':
        context.push('/admin/laporan/$reportId');
        break;
      case 'officer':
        context.push('/officer/tugas/$reportId');
        break;
      default:
        context.push('/citizen/laporan/$reportId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationAsync = ref.watch(notificationDetailProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detail Notifikasi', style: TextStyle(color: AppColors.neutral900)),
      ),
      body: notificationAsync.when(
        data: (notification) {
          if (notification == null) {
            return const Center(child: Text('Notifikasi tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(_getNotificationIcon(notification.type), style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutral900),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notification.isRead ? AppColors.surfaceContainer : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.isRead ? 'Dibaca' : 'Baru',
                              style: TextStyle(
                                fontSize: 12,
                                color: notification.isRead ? AppColors.neutral600 : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Text(notification.body, style: const TextStyle(fontSize: 14, color: AppColors.neutral900, height: 1.5)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.neutral600),
                    const SizedBox(width: 4),
                    Text(_formatDateTime(notification.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                  ],
                ),
                const SizedBox(height: 32),
                if (notification.dataPayload['reportId'] != null)
                  LapButton(
                    onPressed: () => _navigateToRelatedPage(notification),
                    child: Text(_getNotificationAction(notification.type)),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, $hour:$minute';
  }
}
```

---

## 8. GoRouter Configuration

```dart
// filepath: app/lib/core/routing/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/domain_data/auth/domain/auth_provider.dart';
import '../landing/splash/splash_screen.dart';
import '../landing/auth/login/login_screen.dart';
import '../landing/auth/register/register_screen.dart';
import '../landing/auth/forgot_password/forgot_password_screen.dart';
import '../landing/notification/notification_detail_screen.dart';
import '../workspaces/admin_app/screens/admin_dashboard_screen.dart';
import '../workspaces/citizen_app/screens/citizen_dashboard_screen.dart';
import '../workspaces/officer_app/screens/officer_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final isOnSplash = state.matchedLocation == '/';

      if (isOnSplash) return null;

      if (!isLoggedIn && !isOnAuthRoute) return '/login';

      if (isLoggedIn && isOnAuthRoute) {
        final currentUser = ref.read(currentUserProvider).valueOrNull;
        if (currentUser != null) {
          switch (currentUser.role) {
            case 'admin': return '/admin';
            case 'officer': return '/officer';
            default: return '/citizen';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/notification/:userId/:notificationId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final notificationId = state.pathParameters['notificationId']!;
          return NotificationDetailScreen(userId: userId, notificationId: notificationId);
        },
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/citizen', builder: (context, state) => const CitizenDashboardScreen()),
      GoRoute(path: '/officer', builder: (context, state) => const OfficerDashboardScreen()),
    ],
  );
});
```

---

## 9. App Colors

```dart
// filepath: app/lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1E5AA8);
  static const Color primaryLight = Color(0xFF4A82C9);
  static const Color primaryContainer = Color(0xFFD6E3FF);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFF9F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEDEDF5);
  static const Color surfaceContainerLow = Color(0xFFF3F3FA);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EF);
  static const Color outline = Color(0xFF737782);
  static const Color outlineVariant = Color(0xFFC2C6D3);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C21);
  static const Color onSurfaceVariant = Color(0xFF424751);
}
```

---

## 10. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^13.2.0
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_messaging: ^14.7.10
  google_fonts: ^6.1.0
```
