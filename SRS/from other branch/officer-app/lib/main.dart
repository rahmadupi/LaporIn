import 'package:flutter/material.dart';
import 'dart:io'; // TAMBAHAN: Untuk mengabaikan error sertifikat SSL
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Mesin Notifikasi
import 'firebase_options.dart'; 
import 'features/officer/screens/officer_login_screen.dart';
import 'features/officer/screens/officer_home_screen.dart'; // 🐛 DEBUG: untuk bypass home

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

  // ============================================================
  // 🐛 DEBUG: FIREBASE DIMATIKAN — HAPUS BLOK INI UNTUK MEMULIHKAN
  // Try-catch di Firebase.init & FCM agar app TETAP jalan walau Firebase
  // gagal/konfig rusak. Hive (lokal) tetap diinisialisasi penuh.
  // ============================================================
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('[DEBUG] Firebase initialized.');
  } catch (e, st) {
    debugPrint('[DEBUG] Firebase init GAGAL — dilewati: $e\n$st');
  }

  // 3. Bangun Fondasi Database Lokal Hive
  await Hive.initFlutter();
  await Hive.openBox('offline_proofs');

  runApp(const MyApp());
  // ============================================================
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
    // 🐛 DEBUG: Seluruh FCM dibungkus try-catch agar tidak crash saat
    // Firebase tidak tersedia. Hapus blok try-catch ini untuk memulihkan FCM.
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Minta izin notifikasi ke HP pengguna
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // TAKTIK BARU: Masuk ke grup 'relawan' agar tidak butuh Token HP spesifik!
      await messaging.subscribeToTopic('relawan');
      
      print("\n\n==================================================");
      print("✅ APLIKASI SUKSES BERGABUNG KE TOPIK 'relawan'");
      print("==================================================\n\n");

      // Dengarkan notifikasi saat aplikasi sedang dibuka (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null && mounted) {
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
      print("[DEBUG] Gagal setup notifikasi — dilewati: $e");
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
      // 🐛 DEBUG: Loncat langsung ke Home agar UI bisa dieksplorasi tanpa
      // harus login. Ganti kembali ke OfficerLoginScreen() untuk memulihkan.
      home: const OfficerHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}