import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'features/officer/screens/officer_home_screen.dart';

void main() async {
  // Wajib dipanggil sebelum inisialisasi hal lain di main()
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bangun fondasi database lokal Hive di HP
  await Hive.initFlutter();
  
  // 2. Buka sebuah 'laci' khusus bernama 'offline_proofs' 
  // Laci ini akan kita pakai untuk menyimpan foto dan catatan saat offline
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