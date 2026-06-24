/// Exception domain untuk kegagalan autentikasi.
///
/// Kode UI cukup menangkap [AuthFailure] dan menampilkan [message] yang sudah
/// dalam Bahasa Indonesia — tidak perlu tahu detail kode error Firebase.
/// Ini menjaga layer presentation tetap bersih dari ketergantungan SDK.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  /// Pesan ramah-pengguna (sudah diterjemahkan) untuk ditampilkan di snackbar.
  final String message;

  /// Memetakan kode error Firebase Auth ke pesan Bahasa Indonesia.
  ///
  /// Dipusatkan di satu factory agar semua sumber error (login, register,
  /// reset password) memakai terjemahan yang konsisten.
  factory AuthFailure.fromCode(String? code) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure('Format email tidak valid.');
      case 'user-disabled':
        return const AuthFailure('Akun ini telah dinonaktifkan.');
      case 'user-not-found':
        return const AuthFailure('Akun dengan email ini tidak ditemukan.');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Email atau password salah.');
      case 'email-already-in-use':
        return const AuthFailure('Email ini sudah terdaftar.');
      case 'weak-password':
        return const AuthFailure('Password terlalu lemah (minimal 8 karakter).');
      case 'network-request-failed':
        return const AuthFailure('Gagal terhubung. Periksa koneksi internet Anda.');
      case 'too-many-requests':
        return const AuthFailure('Terlalu banyak percobaan. Coba lagi nanti.');
      default:
        return const AuthFailure('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  @override
  String toString() => message;
}
