import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:firebase_core/firebase_core.dart'; // Tambahan import Firebase
import 'firebase_options.dart'; // Tambahan import file opsi dari Izzud
import 'features/officer/screens/officer_home_screen.dart';

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
      home: const OfficerHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}