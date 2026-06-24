import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

/// Model data yang menjembatani tipe Firebase <-> entitas domain [AppUser].
///
/// Memisahkan logika serialisasi (parsing dari/ke Firestore) di sini menjaga
/// entitas domain tetap murni dan tidak "kotor" oleh detail Firebase.
class AppUserModel {
  AppUserModel._();

  /// Membangun [AppUser] dari [User] Firebase + role yang sudah ditentukan.
  ///
  /// Role tidak diambil dari [User] secara langsung karena role berasal dari
  /// custom claims / Firestore (lihat FirebaseAuthRepository.fetchRole).
  static AppUser fromFirebase(User user, UserRole role) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      // displayName bisa null bila profil belum diisi; beri fallback aman.
      displayName: user.displayName ?? '',
      role: role,
    );
  }

  /// Map yang ditulis ke koleksi `users/{uid}` di Firestore saat registrasi
  /// (mengikuti skema bagian 8.1 pada dokumen perencanaan).
  static Map<String, dynamic> toFirestore({
    required String email,
    required String displayName,
    required String phoneNumber,
    required UserRole role,
  }) {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role.value,
      'photoURL': null,
      // serverTimestamp() memakai jam server Firebase, bukan jam device yang
      // bisa salah — penting untuk audit & pengurutan data.
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'fcmTokens': <String>[],
    };
  }
}
