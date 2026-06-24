import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Firebase Auth instance provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// AuthRepository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(auth: ref.watch(firebaseAuthProvider));
});

/// Auth state stream dari Firebase Auth.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Current user provider - mengambil UserEntity lengkap dari Firestore.
final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserEntity?>(
      () => CurrentUserNotifier(),
    );

class CurrentUserNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) async {
        if (user == null) return null;
        final repository = ref.read(authRepositoryProvider);
        return repository.currentUser();
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
