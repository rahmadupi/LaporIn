import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Mengelola registrasi FCM token ke dokumen `users/{uid}`.
///
/// Token disimpan di field array `fcmTokens` agar satu akun bisa menerima push
/// di banyak perangkat. Operasi dibuat best-effort: kegagalan menyimpan token
/// TIDAK boleh menggagalkan login (notifikasi adalah fitur pendukung).
///
/// Dipanggil dari AuthProvider:
///   * [registerForUser] setelah login / pemulihan sesi berhasil.
///   * [unregisterForUser] saat logout (token perangkat ini dibuang).
class FcmTokenService {
  FcmTokenService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  /// Langganan onTokenRefresh aktif; dibatalkan saat user lain login/logout.
  /// (Disimpan agar tidak menumpuk listener tiap kali registerForUser dipanggil.)
  String? _boundUid;

  /// Ambil token perangkat lalu simpan ke profil [uid]. Juga mulai memantau
  /// rotasi token (onTokenRefresh) agar dokumen selalu mutakhir.
  Future<void> registerForUser(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }

      // Pasang listener refresh sekali per uid (FCM bisa merotasi token).
      if (_boundUid != uid) {
        _boundUid = uid;
        _messaging.onTokenRefresh.listen((newToken) {
          if (_boundUid == uid) _saveToken(uid, newToken);
        });
      }
    } catch (e) {
      debugPrint('[FCM] Gagal registrasi token untuk $uid: $e');
    }
  }

  /// Hapus token perangkat ini dari profil [uid] (dipanggil saat logout) agar
  /// perangkat yang sudah logout tidak lagi menerima push milik akun tersebut.
  Future<void> unregisterForUser(String uid) async {
    _boundUid = null;
    if (uid.isEmpty) return;
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('[FCM] Gagal menghapus token untuk $uid: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      // arrayUnion: idempotent — token yang sama tidak menggandakan entri.
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      debugPrint('[FCM] Token tersimpan untuk $uid.');
    } catch (e) {
      debugPrint('[FCM] Gagal menyimpan token untuk $uid: $e');
    }
  }
}
