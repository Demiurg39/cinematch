import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../data/auth_repository.dart';
import '../../data/auth_session_service.dart';
import '../../domain/auth_state.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

@riverpod
AuthSessionService authSessionService(AuthSessionServiceRef ref) {
  return AuthSessionService();
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  StreamSubscription? _authSubscription;

  @override
  AsyncValue<AuthState> build() {
    // Listen to Supabase auth state changes to restore session
    _authSubscription ??= Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final session = data.session;
        if (session != null) {
          final service = ref.read(authSessionServiceProvider);
          await service.saveSession(session);
          final repository = ref.read(authRepositoryProvider);
          final user = await repository.getCurrentUser();
          if (user != null) {
            state = AsyncData(AuthAuthenticated(user));
          }
        }
      },
    );

    ref.onDispose(() => _authSubscription?.cancel());

    return const AsyncData(AuthUnauthenticated());
  }

  Future<void> restoreSession() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(authSessionServiceProvider);
      final hasSession = await service.hasSession();
      if (!hasSession) {
        state = const AsyncData(AuthUnauthenticated());
        return;
      }

      // Supabase client auto-restores from its own storage
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final repository = ref.read(authRepositoryProvider);
        final user = await repository.getCurrentUser();
        if (user != null) {
          state = AsyncData(AuthAuthenticated(user));
          return;
        }
      }

      // Session cookie expired or invalid
      await service.clearSession();
      state = const AsyncData(AuthUnauthenticated());
    } catch (e) {
      state = const AsyncData(AuthUnauthenticated());
    }
  }

  void resetError() {
    if (state.hasError) {
      state = const AsyncData(AuthUnauthenticated());
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(AuthAuthenticated(user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );
      state = AsyncData(AuthAuthenticated(user));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(authSessionServiceProvider);
      await service.clearSession();
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = const AsyncData(AuthUnauthenticated());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}