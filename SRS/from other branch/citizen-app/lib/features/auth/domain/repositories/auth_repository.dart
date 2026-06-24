import '../entities/app_user.dart';
import '../entities/user_role.dart';

/// Kontrak (interface) untuk operasi autentikasi.
///
/// Layer presentation (AuthProvider) hanya bergantung pada abstraksi ini,
/// bukan pada implementasi Firebase langsung. Manfaatnya: implementasi bisa
/// diganti/di-mock saat testing, dan UI tidak pernah memanggil SDK Firebase
/// secara langsung (sesuai aturan NFR-6 — jangan campur UI dengan Firebase).
abstract class AuthRepository {
  /// Stream perubahan status login. Dipakai router untuk reaktif terhadap
  /// login/logout (mis. otomatis kembali ke Login setelah signOut).
  Stream<AppUser?> authStateChanges();

  /// User yang sedang login saat ini (null jika belum login).
  Future<AppUser?> currentUser();

  /// Login dengan email & password (FR-1.1).
  Future<AppUser> signIn({required String email, required String password});

  /// Registrasi akun baru sekaligus menyimpan profil ke Firestore (FR-1.1).
  Future<AppUser> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  });

  /// Mengirim email reset password (Forgot Password screen).
  Future<void> sendPasswordResetEmail(String email);

  /// Logout dan menghapus session (FR-1.4).
  Future<void> signOut();

  /// Mengambil role user dari custom claims (FR-1.3), dengan fallback ke
  /// dokumen Firestore. [forceRefresh] memaksa token di-refresh — penting
  /// untuk mitigasi R6 (claims belum sync setelah pertama kali di-set).
  Future<UserRole> fetchRole({bool forceRefresh = false});
}
