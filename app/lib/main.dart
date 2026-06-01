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
import 'features/auth/presentation/screens/role_placeholder_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/citizen/presentation/screens/citizen_main_navigation.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Wajib dipanggil sebelum memakai plugin async (Firebase) di main().
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase dengan opsi per-platform sebelum runApp, agar
  // FirebaseAuth/Firestore siap dipakai saat widget pertama dibangun.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LaporInApp());
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
      ],
      child: MaterialApp(
        title: 'LaporIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
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
        },
      ),
    );
  }
}
