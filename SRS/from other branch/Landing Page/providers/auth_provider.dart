import 'package:flutter/foundation.dart';

import '../../domain/auth_failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

/// Status proses autentikasi untuk dikonsumsi UI.
enum AuthStatus {
  initial, // Belum ada aksi (dipakai Splash saat mengecek session).
  loading, // Sedang memproses (tombol menampilkan spinner).
  authenticated, // Login berhasil.
  unauthenticated, // Belum login / sudah logout.
  error, // Terjadi kegagalan; lihat errorMessage.
}

/// State management auth memakai ChangeNotifier (pola Provider).
///
/// Bertugas sebagai jembatan antara UI dan [AuthRepository]: UI memanggil
/// method di sini, provider memanggil repository, lalu memanggil
/// [notifyListeners] agar widget yang menyimak ikut rebuild.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  AppUser? _user;
  AppUser? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;

  /// Dipanggil Splash untuk mengecek apakah ada session aktif (FR-1.4).
  /// Mengembalikan role agar Splash bisa menentukan tujuan routing.
  Future<UserRole?> checkSession() async {
    final current = await _repository.currentUser();
    if (current == null) {
      _setUnauthenticated();
      return null;
    }
    _user = current;
    _status = AuthStatus.authenticated;
    notifyListeners();
    return current.role;
  }

  /// Login email/password. Return true jika sukses agar UI bisa navigasi.
  Future<bool> signIn({required String email, required String password}) {
    // Bungkus repository.signIn dalam helper _run agar pola loading/error
    // tidak ditulis ulang di tiap method (signIn/register/reset).
    return _run(() async {
      _user = await _repository.signIn(email: email, password: password);
    });
  }

  /// Registrasi akun baru lalu otomatis dianggap login.
  Future<bool> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) {
    return _run(() async {
      _user = await _repository.register(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );
    });
  }

  /// Kirim email reset password. Tidak mengubah _user, hanya status.
  Future<bool> sendPasswordReset(String email) {
    return _run(() => _repository.sendPasswordResetEmail(email));
  }

  /// Logout: bersihkan state lalu beri tahu listener (FR-1.4).
  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _setUnauthenticated();
  }

  /// Eksekutor bersama: set loading -> jalankan aksi -> tangani sukses/gagal.
  ///
  /// Menangkap [AuthFailure] (pesan sudah diterjemahkan) maupun error tak
  /// terduga, lalu menyimpannya ke [_errorMessage] untuk ditampilkan UI.
  Future<bool> _run(Future<void> Function() action) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners(); // Trigger UI menampilkan spinner.

    try {
      await action();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message; // Pesan sudah ramah-pengguna.
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan tak terduga. Silakan coba lagi.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
