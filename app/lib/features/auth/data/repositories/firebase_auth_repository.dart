import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/auth_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

/// Implementasi konkret [AuthRepository] di atas Firebase Auth + Firestore.
///
/// Semua pemanggilan SDK Firebase terkurung di kelas ini (NFR-6). UI dan
/// AuthProvider tidak pernah menyentuh FirebaseAuth secara langsung.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> authStateChanges() {
    // authStateChanges() memancarkan event tiap user login/logout.
    // asyncMap dipakai karena penentuan role butuh operasi async (ambil token
    // / baca Firestore), sehingga AppUser yang dipancarkan sudah lengkap.
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null; // Belum/tidak login.
      final role = await _resolveRole(user, forceRefresh: false);
      return AppUserModel.fromFirebase(user, role);
    });
  }

  @override
  Future<AppUser?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final role = await _resolveRole(user, forceRefresh: false);
    return AppUserModel.fromFirebase(user, role);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1) Verifikasi kredensial ke Firebase Auth.
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      // 2) Force refresh token agar custom claims role yang terbaru ikut
      //    terbaca (mitigasi R6: claims kadang belum sync di token lama).
      final role = await _resolveRole(user, forceRefresh: true);

      // 3) Catat waktu login terakhir (best-effort, tidak memblok login).
      await _touchLastLogin(user.uid);

      return AppUserModel.fromFirebase(user, role);
    } on FirebaseAuthException catch (e) {
      // Terjemahkan kode Firebase ke pesan Bahasa Indonesia yang ramah user.
      throw AuthFailure.fromCode(e.code);
    }
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    try {
      // 1) Buat akun di Firebase Auth.
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      // 2) Simpan nama ke profil Auth agar langsung tersedia tanpa query DB.
      await user.updateDisplayName(name.trim());

      // 3) Tulis profil lengkap ke Firestore (skema bagian 8.1). Role disimpan
      //    di sini; custom claims di Auth diset belakangan oleh backend/Cloud
      //    Function (client SDK tidak boleh menulis custom claims).
      await _firestore.collection('users').doc(user.uid).set(
            AppUserModel.toFirestore(
              email: email.trim(),
              displayName: name.trim(),
              phoneNumber: phoneNumber.trim(),
              role: role,
            ),
          );

      return AppUserModel.fromFirebase(user, role);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<UserRole> fetchRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.unknown;
    return _resolveRole(user, forceRefresh: forceRefresh);
  }

  /// Menentukan role dengan strategi dua lapis:
  ///   1. Custom claims di Firebase Auth (sumber utama — FR-1.3).
  ///   2. Fallback ke dokumen `users/{uid}` di Firestore bila claim belum ada.
  ///
  /// Fallback ini penting agar demo tetap jalan walau Cloud Function pen-set
  /// custom claims belum aktif (lihat catatan R6 di dokumen perencanaan).
  Future<UserRole> _resolveRole(User user, {required bool forceRefresh}) async {
    try {
      // getIdTokenResult membaca token JWT; forceRefresh menarik token baru.
      final token = await user.getIdTokenResult(forceRefresh);
      final claimRole = token.claims?['role'] as String?;
      if (claimRole != null) {
        return UserRole.fromString(claimRole);
      }

      // Custom claim belum ada -> baca role dari Firestore sebagai cadangan.
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return UserRole.fromString(doc.data()?['role'] as String?);
    } catch (_) {
      // Apa pun kegagalannya, jangan crash—kembalikan unknown agar router
      // bisa mengarahkan user ke layar yang aman.
      return UserRole.unknown;
    }
  }

  /// Update field lastLoginAt secara best-effort (kegagalan diabaikan agar
  /// tidak mengganggu alur login utama).
  Future<void> _touchLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Diabaikan: dokumen mungkin belum ada / offline. Bukan error fatal.
    }
  }
}
