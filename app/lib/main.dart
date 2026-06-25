import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Hive — dipakai oleh ProofUploadService untuk antrean offline
  // (officer M3). Box `offline_proofs` dibuka di awal agar service
  // tidak perlu lazy-init.
  await Hive.initFlutter();
  await Hive.openBox('offline_proofs');

  runApp(const ProviderScope(child: LaporInApp()));
}

class LaporInApp extends ConsumerWidget {
  const LaporInApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LaporIn',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
