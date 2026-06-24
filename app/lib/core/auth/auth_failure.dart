/// Kode error terstruktur untuk AuthFailure, supaya UI dapat
/// membedakan jenis kegagalan (mis. banned vs kredensial salah).
enum AuthErrorCode {
  unknown,
  invalidEmail,
  userDisabled,
  userNotFound,
  wrongPassword,
  invalidCredential,
  emailAlreadyInUse,
  weakPassword,
  networkRequestFailed,
  tooManyRequests,
  emailNotVerified,
  userProfileNotFound,
  pendingOfficer,
  inactive,
  banned,
}

/// Exception domain untuk kegagalan autentikasi.
class AuthFailure implements Exception {
  const AuthFailure(
    this.message, {
    this.code = AuthErrorCode.unknown,
    this.banReason,
    this.bannedAt,
  });

  final AuthErrorCode code;
  final String message;

  /// Alasan pemblokiran (hanya diisi saat [code] == [AuthErrorCode.banned]).
  final String? banReason;

  /// Waktu pemblokiran (hanya diisi saat [code] == [AuthErrorCode.banned]).
  final DateTime? bannedAt;

  /// Buat [AuthFailure] khusus untuk akun yang diblokir.
  ///
  /// Pesan yang ditampilkan menyertakan alasan pemblokiran bila tersedia,
  /// sehingga pengguna mendapat konteks yang jelas mengapa mereka tidak bisa masuk.
  factory AuthFailure.banned({String? reason, DateTime? bannedAt}) {
    final hasReason = reason != null && reason.trim().isNotEmpty;
    final message = hasReason
        ? 'Akun Anda telah diblokir: $reason. Hubungi Admin untuk informasi lebih lanjut.'
        : 'Akun Anda telah diblokir. Hubungi Admin untuk informasi lebih lanjut.';
    return AuthFailure(
      message,
      code: AuthErrorCode.banned,
      banReason: hasReason ? reason : null,
      bannedAt: bannedAt,
    );
  }

  /// Buat [AuthFailure] untuk akun dormant (`status == "inActive"`).
  ///
  /// Akun dormant tidak diblokir — user bisa self re-activate dari
  /// halaman login, atau admin bisa me-reactivate secara manual.
  factory AuthFailure.inactive() {
    return const AuthFailure(
      'Akun Anda saat ini dalam status tidak aktif karena sudah lama tidak digunakan. '
      'Ketuk "Aktifkan Kembali" untuk mengaktifkan akun Anda.',
      code: AuthErrorCode.inactive,
    );
  }

  /// True jika error ini menunjukkan akun diblokir.
  bool get isBanned => code == AuthErrorCode.banned;

  /// True jika error ini menunjukkan akun dormant (`inActive`).
  bool get isInactive => code == AuthErrorCode.inactive;

  /// True jika akun officer masih menunggu persetujuan admin.
  bool get isPendingOfficer => code == AuthErrorCode.pendingOfficer;

  factory AuthFailure.fromCode(String? code) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure(
          'Format email tidak valid.',
          code: AuthErrorCode.invalidEmail,
        );
      case 'user-disabled':
        return const AuthFailure(
          'Akun ini telah dinonaktifkan.',
          code: AuthErrorCode.userDisabled,
        );
      case 'user-not-found':
        return const AuthFailure(
          'Akun dengan email ini tidak ditemukan.',
          code: AuthErrorCode.userNotFound,
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          'Email atau password salah.',
          code: AuthErrorCode.wrongPassword,
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'Email ini sudah terdaftar.',
          code: AuthErrorCode.emailAlreadyInUse,
        );
      case 'weak-password':
        return const AuthFailure(
          'Password terlalu lemah (minimal 8 karakter).',
          code: AuthErrorCode.weakPassword,
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Gagal terhubung. Periksa koneksi internet Anda.',
          code: AuthErrorCode.networkRequestFailed,
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Terlalu banyak percobaan. Coba lagi nanti.',
          code: AuthErrorCode.tooManyRequests,
        );
      default:
        return const AuthFailure(
          'Terjadi kesalahan. Silakan coba lagi.',
          code: AuthErrorCode.unknown,
        );
    }
  }

  @override
  String toString() => message;
}
