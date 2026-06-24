import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

enum ForgotPasswordStatus { initial, loading, success, error }

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final Ref _ref;

  ForgotPasswordNotifier(this._ref) : super(const ForgotPasswordState());

  Future<bool> sendResetLink(String email) async {
    state = state.copyWith(
      status: ForgotPasswordStatus.loading,
      errorMessage: null,
    );

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.sendPasswordResetEmail(email);
      state = state.copyWith(status: ForgotPasswordStatus.success);
      return true;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Terjadi kesalahan tak terduga.',
      );
      return false;
    }
  }

  void reset() {
    state = const ForgotPasswordState();
  }
}

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>((ref) {
      return ForgotPasswordNotifier(ref);
    });
