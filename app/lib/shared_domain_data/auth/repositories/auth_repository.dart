import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/auth/auth_failure.dart';
import '../entities/user_entity.dart';
import '../entities/user_role.dart';
import '../models/user_model.dart';

/// Implementasi AuthRepository menggunakan Firebase Auth + Firestore.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  /// Stream perubahan status login.
  Stream<UserEntity?> authStateChanges() {
    return _auth.authStateChanges().asyncMap(_mapFirebaseUserToEntity);
  }

  /// User yang sedang login saat ini (null jika belum login).
  Future<UserEntity?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchUserEntity(user.uid);
  }

  /// Login dengan email & password.
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Gagal masuk. Silakan coba lagi.');
      }

      // Force refresh ID token agar status emailVerified ter-update
      await user.reload();
      final refreshedUser = _auth.currentUser ?? user;

      // Cek apakah email sudah diverifikasi
      if (!refreshedUser.emailVerified) {
        await _auth.signOut();
        throw const AuthFailure(
          'Verifikasi akun pada email. Silakan cek inbox dan klik link verifikasi.',
        );
      }

      final entity = await _fetchUserEntity(refreshedUser.uid);
      if (entity == null) {
        // RECOVERY FLOW: User ada di Firebase Auth & email terverifikasi,
        // tapi profil Firestore tidak ada (misalnya karena register gagal
        // sebagian atau dokumen terhapus). Auto-create profil default.
        // Ini aman karena email sudah terverifikasi.
        final recoveredEntity = await _recoverUserProfile(refreshedUser);
        if (recoveredEntity == null) {
          await _auth.signOut();
          throw const AuthFailure(
            'Profil pengguna tidak ditemukan. Hubungi admin.',
          );
        }
        return recoveredEntity;
      }

      // === Status transition setelah verifikasi email berhasil ===
      // Jika user baru saja verifikasi email (status masih pending_verification),
      // update status berdasarkan role:
      //   - officer → "pending" (visible ke admin untuk approval)
      //   - citizen/admin → "active"
      if (entity.isPendingVerification) {
        final newStatus = entity.role == UserRole.officer
            ? 'pending'
            : 'active';
        await _db.collection('users').doc(refreshedUser.uid).update({
          'status': newStatus,
          'isAvailable': entity.role == UserRole.officer,
        });
        // Update entity lokal
        final updatedEntity = entity.copyWith(status: newStatus);
        return updatedEntity;
      }

      // Validasi status user
      if (entity.isPendingOfficer) {
        await _auth.signOut();
        throw const AuthFailure('Akun Anda masih menunggu persetujuan Admin.');
      }

      if (entity.isBanned) {
        await _auth.signOut();
        throw AuthFailure.banned(
          reason: entity.banReason,
          bannedAt: entity.bannedAt,
        );
      }

      if (entity.isInactive) {
        await _auth.signOut();
        throw AuthFailure.inactive();
      }

      return entity;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Registrasi akun baru sekaligus menyimpan profil ke Firestore.
  /// Untuk officer, status diset "pending" hingga admin approve.
  Future<UserEntity> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Gagal membuat akun.');
      }

      // Kirim email verifikasi - WAJIB untuk semua role.
      // Jika gagal, throw error agar user tahu ada masalah.
      try {
        await user.sendEmailVerification();
      } catch (e) {
        // Rollback: hapus akun agar user bisa coba lagi
        await user.delete();
        await _auth.signOut();
        throw const AuthFailure(
          'Gagal mengirim email verifikasi. Silakan coba lagi atau hubungi admin.',
        );
      }

      final now = DateTime.now();
      final isOfficer = role == UserRole.officer;

      // Semua role mulai dari "pending_verification" setelah register.
      // Status akan berubah setelah user verifikasi email & login pertama:
      //   - citizen/admin → "active"
      //   - officer → "pending" (menunggu admin approve)
      final entity = UserEntity(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        status: UserStatus.pendingVerification.value,
        isAvailable: isOfficer,
        createdAt: now,
      );

      await _db
          .collection('users')
          .doc(user.uid)
          .set(UserModel.toFirestore(entity));

      // Sign out agar user login manual setelah verifikasi email
      await _auth.signOut();

      return entity;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Mengirim email reset password.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    }
  }

  /// Re-aktifkan akun dormant (`status: "inActive"` → `"active"`).
  ///
  /// Dipanggil dari tombol "Aktifkan Kembali" di halaman login, atau
  /// oleh admin dari halaman user-moderation. Hanya dilakukan untuk akun
  /// yang saat ini ber-status `inActive`; status lain akan diabaikan
  /// (tidak akan meniban status `banned` dll.).
  Future<UserEntity> reactivateDormantAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure(
        'Sesi login tidak ditemukan. Silakan login ulang.',
        code: AuthErrorCode.userNotFound,
      );
    }

    // Penting: baca dari server (bukan cache) untuk memastikan status
    // terkini. Tanpa ini, akun yang baru di-flag dormant mungkin masih
    // terbaca sebagai "active" di cache lokal.
    final entity = await _fetchUserEntity(user.uid, forceRefresh: true);
    if (entity == null) {
      throw const AuthFailure(
        'Profil pengguna tidak ditemukan.',
        code: AuthErrorCode.userProfileNotFound,
      );
    }

    if (!entity.isInactive) {
      // Bukan dormant - tidak melakukan perubahan. Kembalikan entity apa adanya.
      return entity;
    }

    await _db.collection('users').doc(user.uid).update({
      'status': UserStatus.active.value,
    });

    return entity.copyWith(status: UserStatus.active.value);
  }

  /// Logout dan menghapus session. Tunggu sebentar untuk memastikan
  /// auth state telah update di semua provider sebelum return.
  Future<void> signOut() async {
    await _auth.signOut();
    // Tunggu sebentar agar authStateProvider stream emit null
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Mengambil role user dari dokumen Firestore.
  Future<UserRole> fetchRole({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return UserRole.unknown;
    final entity = await _fetchUserEntity(user.uid, forceRefresh: forceRefresh);
    return entity?.role ?? UserRole.unknown;
  }

  // ============ Private helpers ============

  Future<UserEntity?> _mapFirebaseUserToEntity(User? user) async {
    if (user == null) return null;
    return _fetchUserEntity(user.uid);
  }

  /// Recovery flow: Buat profil default untuk user yang ada di Firebase Auth
  /// tapi belum punya dokumen di Firestore. Hanya dilakukan jika email
  /// sudah terverifikasi dan kita bisa ambil nama dari displayName/profile.
  Future<UserEntity?> _recoverUserProfile(User user) async {
    try {
      // Defensive: Selalu baca dari server untuk konfirmasi dokumen benar-benar
      // tidak ada. Cache lokal bisa kosong/stale sehingga _fetchUserEntity
      // sebelumnya mengembalikan null meskipun profil sebenarnya sudah ada.
      // Tanpa pengecekan ini, kita bisa menimpa akun admin dengan profil
      // default (citizen + nama email).
      final existing = await _db
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      if (existing.exists) {
        return UserModel.fromFirestore(existing);
      }

      // Default ke citizen role untuk safety
      final displayName =
          user.displayName ?? user.email?.split('@').first ?? 'User';
      final phoneNumber = user.phoneNumber ?? '+62';

      final entity = UserEntity(
        uid: user.uid,
        fullName: displayName,
        email: user.email ?? '',
        phoneNumber: phoneNumber,
        role: UserRole.citizen,
        status: UserStatus.active.value,
        isAvailable: false,
        createdAt: DateTime.now(),
      );

      // Hanya tulis jika memang belum ada dokumen (merge aman sebagai
      // jaring pengaman tambahan, walaupun pengecekan di atas seharusnya
      // sudah cukup).
      await _db
          .collection('users')
          .doc(user.uid)
          .set(UserModel.toFirestore(entity), SetOptions(merge: true));

      return entity;
    } catch (_) {
      return null;
    }
  }

  Future<UserEntity?> _fetchUserEntity(
    String uid, {
    bool forceRefresh = false,
  }) async {
    try {
      // Penting: gunakan default source (cache-first, server-fallback) bukan
      // Source.cache saja. Jika cache kosong / stale, read sebelumnya akan
      // mengembalikan null dan memicu _recoverUserProfile yang me-replace
      // dokumen user asli dengan profil default (citizen + nama email).
      final doc = forceRefresh
          ? await _db
                .collection('users')
                .doc(uid)
                .get(const GetOptions(source: Source.server))
          : await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }
}
