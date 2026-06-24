import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/citizen/data/repositories/firebase_watch_zone_repository.dart';
import 'features/citizen/domain/repositories/watch_zone_repository.dart';
import 'features/citizen/presentation/screens/citizen_main_navigation.dart';
import 'features/notifications/data/firebase_notification_repository.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/presentation/screens/notification_screen.dart';
import 'features/reports/data/repositories/firebase_reports_repository.dart';
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

  // Inisialisasi Firebase dengan opsi per-platform sebelum runApp, agar
  // FirebaseAuth/Firestore siap dipakai saat widget pertama dibangun.
  //
  // Firebase bisa ter-init oleh layer native sebelum main() Dart berjalan,
  // sehingga Firebase.apps.isEmpty kadang masih true saat dipanggil namun
  // initializeApp tetap melempar duplicate-app (race). Tangkap & abaikan agar
  // exception tak menggagalkan main() dan menahan runApp().
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const LaporInApp());

  // Init FCM setelah runApp agar permission dialog tidak menahan frame pertama.
  // runApp() non-blocking — async continuation ini berjalan segera setelahnya.
  //
  // Push notification kini RECEIVE-ONLY: tanpa server (Cloud Functions butuh
  // Blaze) tidak ada yang mengirim push, dan koleksi `notifications` tetap
  // kosong sampai ada backend yang mengisinya. Init dibungkus try/catch agar
  // kegagalan apa pun (mis. tanpa Google Play Services) tidak menggagalkan app.
  try {
    await NotificationService(
      navigatorKey: navigatorKey,
      messengerKey: scaffoldMessengerKey,
    ).init();
  } catch (e) {
    debugPrint('[FCM] Init dilewati (fitur push opsional): $e');
  }
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
        Provider<AuthRepository>(
          create: (_) => FirebaseAuthRepository(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        // Repository laporan disuntik di sini agar alur Buat Laporan bisa
        // membaca implementasi Firebase tanpa meng-import SDK di UI (NFR-6).
        Provider<ReportsRepository>(
          create: (_) => FirebaseReportsRepository(),
        ),
        // Repository notifikasi & watch zone (data REAL Firestore) untuk fitur
        // Notification Center dan Watch Zones.
        Provider<NotificationRepository>(
          create: (_) => FirebaseNotificationRepository(),
        ),
        Provider<WatchZoneRepository>(
          create: (_) => FirebaseWatchZoneRepository(),
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
          AppRoutes.createReport: (_) => const ReportFlowScreen(),
          AppRoutes.citizenReports: (_) => const ReportHistoryScreen(),
          AppRoutes.citizenNotifications: (_) => const NotificationScreen(),
        },
      ),
    );
  }
}
