/// Kumpulan validator form yang dipakai bersama oleh Login & Register.
///
/// Dipusatkan agar aturan validasi (mis. panjang password) seragam di seluruh
/// aplikasi dan tidak ditulis ulang per-screen.
class Validators {
  Validators._();

  /// Validasi email: wajib diisi & format harus mengandung pola dasar email.
  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email wajib diisi';
    // Regex sederhana: ada teks, '@', domain, dan titik. Cukup untuk UI;
    // validasi sebenarnya tetap dilakukan Firebase.
    final regex = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$');
    if (!regex.hasMatch(input)) return 'Format email tidak valid';
    return null;
  }

  /// Validasi password: minimal 8 karakter (sesuai hint mockup Register).
  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password wajib diisi';
    if (input.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  /// Validasi field wajib generik (nama, dll).
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  /// Validasi konfirmasi password harus sama dengan password awal.
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
    if (value != original) return 'Konfirmasi password tidak cocok';
    return null;
  }

  /// Validasi nomor HP: wajib & hanya angka, minimal 8 digit.
  static String? phone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Nomor HP wajib diisi';
    if (!RegExp(r'^\d{8,15}$').hasMatch(input)) {
      return 'Nomor HP tidak valid';
    }
    return null;
  }
}
