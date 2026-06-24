import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../reports/presentation/screens/report_detail_screen.dart';

/// Handler pesan saat aplikasi BACKGROUND atau TERMINATED.
///
/// PENTING: handler ini WAJIB berupa fungsi TOP-LEVEL (atau static) dan diberi
/// anotasi @pragma('vm:entry-point') supaya tidak ikut ter-tree-shake pada
/// build release. Saat pesan tiba dan app tidak di foreground, Flutter
/// menjalankannya di ISOLATE TERPISAH — tidak ada akses ke widget/Navigator di
/// sini, jadi cukup untuk pekerjaan ringan (logging/sinkronisasi data).
///
/// Navigasi deep link TIDAK dilakukan di sini, melainkan saat user MENGETUK
/// notifikasi (lihat onMessageOpenedApp & getInitialMessage di service).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Bila perlu memakai plugin Firebase lain di sini, panggil
  // Firebase.initializeApp() lebih dulu karena isolate ini terpisah.
  debugPrint('Pesan background diterima: ${message.messageId}');
}

/// Mengatur seluruh siklus push notification (FCM) untuk LaporIn.
///
/// Menerima [navigatorKey] & [messengerKey] dari root app agar bisa melakukan
/// navigasi dan menampilkan banner dari LUAR widget tree (dipicu oleh event
/// FCM, bukan oleh interaksi UI biasa).
class NotificationService {
  NotificationService({
    required this.navigatorKey,
    required this.messengerKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Inisialisasi izin + seluruh listener untuk tiga kondisi app.
  Future<void> init() async {
    // 1) Minta izin notifikasi (wajib di iOS & Android 13+).
    await _messaging.requestPermission();

    // 2) Daftarkan handler background/terminated (fungsi top-level di atas).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3) FOREGROUND: app sedang dibuka. FCM tidak menampilkan notifikasi sistem
    //    otomatis, jadi kita tampilkan banner in-app sendiri.
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);

    // 4) BACKGROUND: app hidup di belakang lalu notifikasi diketuk -> deep link.
    FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);

    // 5) TERMINATED: app mati total lalu dibuka lewat ketukan notifikasi.
    //    getInitialMessage() mengembalikan pesan pemicunya (null jika app
    //    dibuka normal).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Tunda sampai frame pertama agar Navigator sudah siap sebelum push.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _routeFromMessage(initialMessage),
      );
    }
  }

  /// Banner in-app saat notifikasi tiba di foreground; sertakan aksi "Lihat"
  /// bila ada reportId untuk membuka detail langsung.
  void _showForegroundBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final reportId = message.data['reportId'] as String?;

    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            notification.title ?? notification.body ?? 'Notifikasi baru',
          ),
          action: (reportId != null && reportId.isNotEmpty)
              ? SnackBarAction(
                  label: 'Lihat',
                  onPressed: () => _routeFromMessage(message),
                )
              : null,
        ),
      );
  }

  /// Logika DEEP LINK: jika payload memuat `reportId`, navigasikan langsung ke
  /// ReportDetailScreen untuk laporan tersebut.
  void _routeFromMessage(RemoteMessage message) {
    final reportId = message.data['reportId'] as String?;
    if (reportId == null || reportId.isEmpty) return;

    // Pakai navigatorKey root agar bisa push tanpa BuildContext dari UI.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(reportId: reportId),
      ),
    );
  }
}
