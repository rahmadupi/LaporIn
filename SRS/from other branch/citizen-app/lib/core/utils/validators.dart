/// Kumpulan validator form yang dipakai bersama oleh Login & Register.
class Validators {
  Validators._();

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$');
    if (!regex.hasMatch(input)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password wajib diisi';
    if (input.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty)
      return 'Konfirmasi password wajib diisi';
    if (value != original) return 'Konfirmasi password tidak cocok';
    return null;
  }

  static String? phone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Nomor HP wajib diisi';
    if (!RegExp(r'^\d{8,15}$').hasMatch(input)) {
      return 'Nomor HP tidak valid';
    }
    return null;
  }
}
