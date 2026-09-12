import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

/// Auth state — null means unauthenticated.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    // On startup: try to restore session from secure storage.
    return ref.read(authRepositoryProvider).getStoredUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  bool get isLoggedIn => state.value != null;
  AuthUser? get user   => state.value;
}
