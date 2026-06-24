import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

enum LoginStatus { initial, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({this.status = LoginStatus.initial, this.errorMessage});

  LoginState copyWith({LoginStatus? status, String? errorMessage}) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final Ref _ref;

  LoginNotifier(this._ref) : super(const LoginState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: LoginStatus.loading, errorMessage: null);

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
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: 'Terjadi kesalahan tak terduga.',
      );
      return false;
    }
  }

  void reset() {
    state = const LoginState();
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref);
});
