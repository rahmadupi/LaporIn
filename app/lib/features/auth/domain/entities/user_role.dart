/// Peran user di sistem LaporIn (FR-1.2).
///
/// Nilai enum sengaja dipisah dari string mentah Firebase supaya kode UI
/// bekerja dengan tipe yang aman (type-safe), bukan membandingkan string.
enum UserRole {
  citizen,
  officer,
  admin,
  unknown; // Dipakai bila claim/role tidak dikenali — mencegah crash.

  /// Mengubah string dari Firebase (custom claims / field Firestore) ke enum.
  ///
  /// Memakai switch eksplisit agar setiap role tervalidasi; role tak dikenal
  /// jatuh ke [UserRole.unknown] alih-alih melempar exception.
  static UserRole fromString(String? value) {
    switch (value) {
      case 'citizen':
        return UserRole.citizen;
      case 'officer':
        return UserRole.officer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  /// Nilai string yang disimpan ke Firestore (kebalikan [fromString]).
  String get value => name;
}
