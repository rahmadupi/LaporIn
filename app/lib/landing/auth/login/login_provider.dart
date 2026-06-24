import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../shared_domain_data/auth/entities/user_entity.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;
  final AuthErrorCode? errorCode;
  final String? banReason;
  final DateTime? bannedAt;
  final bool isReactivating;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.errorCode,
    this.banReason,
    this.bannedAt,
    this.isReactivating = false,
  });

  /// True jika error saat ini adalah akun yang diblokir.
  bool get isBanned => errorCode == AuthErrorCode.banned;

  /// True jika error saat ini adalah akun dormant (`inActive`).
  bool get isInactive => errorCode == AuthErrorCode.inactive;

  bool get hasError => status == LoginStatus.error && errorMessage != null;

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    AuthErrorCode? errorCode,
    String? banReason,
    DateTime? bannedAt,
    bool? isReactivating,
    bool clearError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      banReason: clearError ? null : (banReason ?? this.banReason),
      bannedAt: clearError ? null : (bannedAt ?? this.bannedAt),
      isReactivating: isReactivating ?? this.isReactivating,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginNotifier(this._ref) : super(const LoginState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: LoginStatus.loading, clearError: true);

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.signIn(email: email, password: password);

      // Refresh currentUserProvider agar router mendengar perubahan user
      await _ref.read(currentUserProvider.notifier).refresh();

      state = state.copyWith(status: LoginStatus.success);
      return true;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: failure.message,
        errorCode: failure.code,
        banReason: failure.banReason,
        bannedAt: failure.bannedAt,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Terjadi kesalahan tak terduga.',
        errorCode: AuthErrorCode.unknown,
      );
      return false;
    }
  }

  /// Re-aktifkan akun dormant. Dipanggil dari tombol "Aktifkan Kembali"
  /// di dormant-account card. Setelah re-aktif, otomatis sign-in user
  /// dengan kredensial yang sama (yang sebelumnya gagal karena dormant).
  ///
  /// Mengembalikan [UserEntity] yang sudah aktif jika berhasil.
  Future<UserEntity?> reactivateAndSignIn(String email, String password) async {
    state = state.copyWith(isReactivating: true, clearError: true);

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.reactivateDormantAccount();

      // Refresh currentUserProvider agar router mendengar perubahan user
      await _ref.read(currentUserProvider.notifier).refresh();

      // Setelah re-aktif, ulangi sign-in dengan kredensial yang sama
      final success = await login(email, password);

      if (success) {
        return _ref.read(currentUserProvider).valueOrNull;
      }
      return null;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: failure.message,
        errorCode: failure.code,
        isReactivating: false,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Gagal mengaktifkan akun. Silakan coba lagi.',
        errorCode: AuthErrorCode.unknown,
        isReactivating: false,
      );
      return null;
    }
  }

  void reset() {
    state = const LoginState();
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});
