import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_failure.dart';
import '../../../shared_domain_data/auth/entities/user_role.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';

enum RegisterStatus { initial, loading, success, error }

class RegisterState {
  final RegisterStatus status;
  final String? errorMessage;
  final bool officerPendingApproval;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errorMessage,
    this.officerPendingApproval = false,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    String? errorMessage,
    bool? officerPendingApproval,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      officerPendingApproval:
          officerPendingApproval ?? this.officerPendingApproval,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;

  RegisterNotifier(this._ref) : super(const RegisterState());

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(status: RegisterStatus.loading, errorMessage: null);

    try {
      final repository = _ref.read(authRepositoryProvider);
      await repository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        role: role,
      );

      final isOfficer = role == UserRole.officer;
      state = state.copyWith(
        status: RegisterStatus.success,
        officerPendingApproval: isOfficer,
      );
      return true;
    } on AuthFailure catch (failure) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: failure.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Terjadi kesalahan tak terduga.',
      );
      return false;
    }
  }

  void reset() {
    state = const RegisterState();
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>(
  (ref) {
    return RegisterNotifier(ref);
  },
);
