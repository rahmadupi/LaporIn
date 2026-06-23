import 'package:flutter/material.dart';
import 'dart:io'; // TAMBAHAN: Untuk mengabaikan error sertifikat SSL
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Mesin Notifikasi
import 'firebase_options.dart'; 
import 'features/officer/screens/officer_login_screen.dart';

// TAMBAHAN: Class sakti untuk bypass verifikasi SSL (menangani error CERTIFICATE_VERIFY_FAILED dari ImgBB)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Fungsi untuk menangani notifikasi saat aplikasi ditutup (Background)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notifikasi masuk (Background): ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TAMBAHAN: Pasang override HTTP di sini sebelum aplikasi memuat koneksi internet apa pun
  HttpOverrides.global = MyHttpOverrides();

  // 1. Nyalakan Mesin Firebase Cloud
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Daftarkan fungsi background notifikasi
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Bangun Fondasi Database Lokal Hive
  await Hive.initFlutter();
  await Hive.openBox('offline_proofs');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupPushNotifications();
  }

  // Konfigurasi perizinan dan pendengar notifikasi via TOPIK
  Future<void> _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Minta izin notifikasi ke HP pengguna
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    try {
      // TAKTIK BARU: Masuk ke grup 'relawan' agar tidak butuh Token HP spesifik!
      await messaging.subscribeToTopic('relawan');
      
      print("\n\n==================================================");
      print("✅ APLIKASI SUKSES BERGABUNG KE TOPIK 'relawan'");
      print("==================================================\n\n");

      // Dengarkan notifikasi saat aplikasi sedang dibuka (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🔔 ${message.notification!.title}: ${message.notification!.body}"),
              backgroundColor: Colors.blue[800],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      print("Gagal setup notifikasi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaporIn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OfficerLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}