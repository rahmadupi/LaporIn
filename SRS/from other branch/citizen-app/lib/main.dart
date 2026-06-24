import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/entities/app_user.dart';
import 'features/auth/domain/entities/user_role.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/role_placeholder_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/citizen/presentation/screens/citizen_main_navigation.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/notifications/presentation/screens/notification_screen.dart';
import 'features/reports/data/repositories/firebase_reports_repository.dart';
import 'features/reports/domain/entities/report.dart';
import 'features/reports/domain/entities/report_category.dart';
import 'features/reports/domain/entities/report_severity.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/presentation/screens/report_flow_screen.dart';
import 'features/reports/presentation/screens/report_history_screen.dart';
import 'firebase_options.dart';

/// Key global Navigator & ScaffoldMessenger.
///
/// Dipakai [NotificationService] agar bisa melakukan navigasi (deep link) dan
/// menampilkan banner dari luar widget tree saat dipicu event FCM.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  // Wajib dipanggil sebelum memakai plugin async (Firebase) di main().
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // 🐛 DEBUG: FIREBASE DIMATIKAN — HAPUS BLOK INI UNTUK MEMULIHKAN
  // Try-catch di Firebase.initializeApp() agar app TETAP jalan walau
  // Firebase gagal/konfig rusak. NotificationService.init() juga
  // diamankan dengan try-catch agar FCM tidak menghambat startup.
  // ============================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[DEBUG] Firebase initialized successfully.');
  } catch (e, st) {
    debugPrint('[DEBUG] Firebase init GAGAL — dilewati: $e\n$st');
  }

  try {
    await NotificationService(
      navigatorKey: navigatorKey,
      messengerKey: scaffoldMessengerKey,
    ).init();
    debugPrint('[DEBUG] NotificationService initialized.');
  } catch (e, st) {
    debugPrint('[DEBUG] NotificationService init GAGAL — dilewati: $e\n$st');
  }
  // ============================================================

  runApp(const LaporInApp());
}

/// Stub AuthRepository — dipakai saat Firebase dimatikan (mode debug).
///
/// Mengembalikan user palsu dengan role [UserRole.citizen] sehingga UI bisa
/// menampilkan data realistis tanpa harus login sungguhan.
class _StubAuthRepository implements AuthRepository {
  final _fakeUser = AppUser(
    uid: 'debug-uid-001',
    email: 'debug.citizen@laporin.app',
    displayName: 'Debug Citizen',
    role: UserRole.citizen,
  );

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _fakeUser;
  }

  @override
  Future<AppUser?> currentUser() async => _fakeUser;

  @override
  Future<AppUser> signIn({required String email, required String password}) async =>
      _fakeUser;

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async =>
      _fakeUser.copyWith(role: role);

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<UserRole> fetchRole({bool forceRefresh = false}) async => UserRole.citizen;
}

/// Stub ReportsRepository — tidak menyentuh Firebase;embalikan list kosong.
class _StubReportsRepository implements ReportsRepository {
  @override
  Future<String> createReport({
    required String reporterId,
    required bool isAnonymous,
    required ReportCategory category,
    required File photo,
    required double latitude,
    required double longitude,
    required String address,
    required String description,
    required ReportSeverity severity,
  }) async =>
      'stub-report-id';

  @override
  Stream<List<Report>> watchUserReports(String reporterId) =>
      const Stream<List<Report>>.empty();

  @override
  Stream<Report?> watchReport(String reportId) => const Stream<Report?>.empty();

  @override
  Future<void> updateDescription({
    required String reportId,
    required String description,
  }) async {}

  @override
  Future<void> softDelete(String reportId) async {}

  @override
  Future<void> submitRating({
    required String reportId,
    required String reporterId,
    required int stars,
    required String comment,
  }) async {}
}

class LaporInApp extends StatelessWidget {
  const LaporInApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider menyuntikkan dependency dari atas pohon widget:
    //   - AuthRepository (implementasi Firebase) sebagai abstraksi.
    //   - AuthProvider yang menerima repository tsb lewat constructor.
    // Pola dependency injection ini membuat UI tak pernah meng-import Firebase.
    return MultiProvider(
      providers: [
        // 🐛 DEBUG: gunakan stub repo (Firebase dimatikan). Ganti kembali ke
        // FirebaseAuthRepository() & FirebaseReportsRepository() untuk
        // memulihkan implementasi Firebase sungguhan.
        Provider<AuthRepository>(
          create: (_) => _StubAuthRepository(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        // Repository laporan disuntik di sini agar alur Buat Laporan bisa
        // membaca implementasi Firebase tanpa meng-import SDK di UI (NFR-6).
        Provider<ReportsRepository>(
          create: (_) => _StubReportsRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'LaporIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Key global agar NotificationService bisa navigasi & tampilkan banner.
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        initialRoute: AppRoutes.splash,
        // Tabel route terpusat; named routes memudahkan navigasi antar fitur.
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          // Citizen masuk ke Main Navigation (bottom nav + tab), bukan langsung
          // ke Home, agar semua tab citizen berada di bawah satu cangkang.
          AppRoutes.citizenHome: (_) => const CitizenMainNavigation(),
          AppRoutes.officerHome: (_) =>
              const RolePlaceholderScreen(title: 'Beranda Petugas'),
          AppRoutes.adminHome: (_) =>
              const RolePlaceholderScreen(title: 'Beranda Admin'),
          AppRoutes.createReport: (_) => const ReportFlowScreen(),
          AppRoutes.citizenReports: (_) => const ReportHistoryScreen(),
          AppRoutes.citizenNotifications: (_) => const NotificationScreen(),
        },
      ),
    );
  }
}
