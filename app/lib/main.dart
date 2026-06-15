import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
// UBAH IMPORT: Sekarang kita arahkan pintu masuk ke halaman Login
import 'features/officer/screens/officer_login_screen.dart';

void main() async {
  // Wajib dipanggil pertama kali untuk mengunci biner Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Nyalakan Mesin Firebase Cloud
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Bangun Fondasi Database Lokal Hive
  await Hive.initFlutter();
  await Hive.openBox('offline_proofs');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaporIn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // UBAH HOME: Halaman pertama kali dibuka adalah Login
      home: const OfficerLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}