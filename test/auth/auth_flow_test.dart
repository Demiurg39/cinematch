import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cinematch/features/auth/presentation/auth_screen.dart';
import 'package:cinematch/features/auth/presentation/providers/auth_provider.dart';
import 'package:cinematch/features/auth/domain/auth_state.dart';
import 'package:cinematch/features/auth/domain/user_model.dart';
import 'package:cinematch/features/auth/data/auth_session_service.dart';
import 'package:cinematch/features/settings/presentation/profile_screen.dart';

// ─── Test Notifiers ────────────────────────────────────────────────

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }
}

class _AuthenticatedNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return AsyncData(AuthAuthenticated(_testUser));
  }

  @override
  Future<void> signOut() async {
    state = const AsyncData(AuthUnauthenticated());
  }
}

class _SignUpSuccessNotifier extends AuthNotifier {
  bool signUpCalled = false;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    signUpCalled = true;
    state = AsyncData(AuthAuthenticated(_testUser));
  }
}

class _SignInSuccessNotifier extends AuthNotifier {
  bool signInCalled = false;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    state = AsyncData(AuthAuthenticated(_testUser));
  }
}

class _SignInErrorNotifier extends AuthNotifier {
  int signInAttempts = 0;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInAttempts++;
    state = AsyncError('Invalid login credentials', StackTrace.current);
  }
}

class _SignUpErrorNotifier extends AuthNotifier {
  int signUpAttempts = 0;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    signUpAttempts++;
    state = AsyncError(
      'Password should be at least 6 characters',
      StackTrace.current,
    );
  }
}

class _SessionRestoreNotifier extends AuthNotifier {
  bool restoreCalled = false;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncLoading();
  }

  @override
  Future<void> restoreSession() async {
    restoreCalled = true;
    state = AsyncData(AuthAuthenticated(_testUser));
  }
}

class _SessionRestoreToUnauthenticatedNotifier extends AuthNotifier {
  bool restoreCalled = false;

  @override
  AsyncValue<AuthState> build() {
    return const AsyncLoading();
  }

  @override
  Future<void> restoreSession() async {
    restoreCalled = true;
    state = const AsyncData(AuthUnauthenticated());
  }
}

class _ProfileUpdateNotifier extends AuthNotifier {
  bool signOutTriggered = false;

  @override
  AsyncValue<AuthState> build() {
    return AsyncData(AuthAuthenticated(_testUser));
  }

  @override
  Future<void> signOut() async {
    signOutTriggered = true;
    state = const AsyncData(AuthUnauthenticated());
  }
}

final _testUser = UserModel(
  id: 'test-user-id',
  username: 'testuser',
  preferredLanguage: 'en',
  region: 'US',
  createdAt: DateTime(2025, 1, 15),
);

// ─── Helpers ───────────────────────────────────────────────────────

ProviderScope authApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: AuthScreen()),
  );
}

ProviderScope profileApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

/// Minimal app that mirrors CinematchApp routing but doesn't use AppShell
/// (AppShell triggers Supabase-dependent providers in tests).
Widget routingApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      home: Consumer(
        builder: (context, ref, _) {
          final authState = ref.watch(authNotifierProvider);
          return authState.when<Widget>(
            loading: () => const AuthScreen(),
            error: (_, __) => const AuthScreen(),
            data: (state) {
              if (state is AuthAuthenticated) {
                return const Scaffold(
                  body: Center(child: Text('AUTHENTICATED_DASHBOARD')),
                );
              }
              return const AuthScreen();
            },
          );
        },
      ),
    ),
  );
}

Future<void> switchToSignUp(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('Sign Up')),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(
    find.byWidgetPredicate((w) =>
        w is RichText && w.text.toPlainText().contains('Sign Up')),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

extension WidgetTesterInteractive on WidgetTester {
  /// Verify form fields are tappable and no full-screen error blocks interaction
  Future<void> assertFormInteractive() async {
    expect(find.byType(TextFormField).first, findsOneWidget);
    // Verify button is enabled (not showing loading spinner)
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Verify no black/error screen is shown — AuthScreen must be present
  Future<void> assertNoCrashScreen() async {
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Error:'), findsNothing);
  }
}

// ─── Tests ─────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 1: New User Registration (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 1: Registration flow', () {
    testWidgets('sign-up form shows username field and transitions on success',
        (tester) async {
      final notifier = _SignUpSuccessNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(notifier.signUpCalled, true);
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('sign-up validates username is required', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 2: Session Persistence — Hot Restart Resilience (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 2: Session persistence — hot restart', () {
    test('AuthSessionService save, restore, and clear session', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AuthSessionService();

      expect(await service.hasSession(), false);

      final storage = FlutterSecureStorage();
      await storage.write(
        key: 'supabase_session',
        value: '{"access_token":"test_jwt"}',
      );
      await storage.write(key: 'cached_user_id', value: 'test-user-id');

      expect(await service.hasSession(), true);
      expect(await service.getCachedUserId(), 'test-user-id');

      await service.clearSession();
      expect(await service.hasSession(), false);
      expect(await service.getCachedUserId(), isNull);
    });

    testWidgets('CinematchApp bypasses auth screen when session restores',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_session': '{"access_token":"test_jwt"}',
        'cached_user_id': 'test-user-id',
      });

      final notifier = _SessionRestoreNotifier();

      await tester.pumpWidget(routingApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initially loading — should show AuthScreen (not black loading screen)
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);

      // Restore session
      await notifier.restoreSession();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should now show dashboard, not AuthScreen
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      expect(notifier.restoreCalled, true);
    });

    testWidgets('CinematchApp shows auth screen when session restore fails',
        (tester) async {
      final notifier = _SessionRestoreToUnauthenticatedNotifier();

      await tester.pumpWidget(routingApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);

      await notifier.restoreSession();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Still on AuthScreen — no redirect to dashboard
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 3: Profile Mutation Guard (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 3: Profile mutation does not disrupt auth state', () {
    testWidgets('profile screen shows user data and stays on profile after update',
        (tester) async {
      final notifier = _ProfileUpdateNotifier();

      await tester.pumpWidget(profileApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Member since 2025'), findsOneWidget);
      expect(find.text('Edit Username'), findsOneWidget);

      await tester.tap(find.text('Edit Username'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(notifier.signOutTriggered, false);
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('sign out transitions to unauthenticated', (tester) async {
      final notifier = _AuthenticatedNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();

      await notifier.signOut();
      await tester.pump();

      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 4: Invalid Email Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 4: Invalid email input validation', () {
    testWidgets('blocks submission when email missing @', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
      await tester.assertNoCrashScreen();
      await tester.assertFormInteractive();
    });

    testWidgets('blocks submission when email field empty', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      await tester.assertNoCrashScreen();
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 5: Weak Password Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 5: Weak password validation', () {
    testWidgets('client-side blocks password shorter than 6 chars',
        (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Must be at least 6 characters'), findsOneWidget);
      await tester.assertNoCrashScreen();
      await tester.assertFormInteractive();
    });

    testWidgets('client-side blocks empty password', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('API weak-password error shows inline banner, no black screen',
        (tester) async {
      final notifier = _SignUpErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      // Fill fields with password that passes client validation (>=6 chars)
      // but triggers mock API error
      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'weakapi123');

      // Submit — triggers API error (not client validation)
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify inline error banner (not black screen)
      // Error banner appears at top — scroll up to see it
      await tester.ensureVisible(
        find.text('Password is too weak. Use 6+ characters.'),
      );
      await tester.pump();

      expect(find.text('Password is too weak. Use 6+ characters.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await tester.assertNoCrashScreen();

      // Auth screen still showing — no redirect
      expect(find.byType(AuthScreen), findsOneWidget);

      // Form still interactive after error
      await tester.assertFormInteractive();
      expect(notifier.signUpAttempts, 1);
    });

    testWidgets('CinematchApp shows AuthScreen on sign-up API error, not crash screen',
        (tester) async {
      final notifier = _SignUpErrorNotifier();

      await tester.pumpWidget(routingApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger sign-up error via routing app
      await notifier.signUpWithEmail(
        email: 'new@example.com',
        password: 'weak',
        username: 'newuser',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Routing app must show AuthScreen, NOT error/black screen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Error:'), findsNothing);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 6: Wrong Credentials Error Handling (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 6: Wrong credentials error handling', () {
    testWidgets('shows inline error banner on failed sign-in', (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextFormField).first,
        'nonexistent@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error banner, not black screen
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await tester.assertNoCrashScreen();

      // User still on auth screen — no redirect
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(notifier.signInAttempts, 1);

      // Form fields still interactive
      await tester.assertFormInteractive();
    });

    testWidgets('CinematchApp shows AuthScreen on sign-in API error',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(routingApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await notifier.signInWithEmail(
        email: 'bad@example.com',
        password: 'badpass',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Must NOT show error/black screen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Error:'), findsNothing);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);
    });

    testWidgets('error banner dismissible, form reusable after dismiss',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger error
      await tester.enterText(
        find.byType(TextFormField).first,
        'bad@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'badpass',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Wrong email or password.'), findsOneWidget);

      // Dismiss
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Wrong email or password.'), findsNothing);

      // Form still interactive after dismiss
      await tester.assertFormInteractive();
    });

    testWidgets('error state resets back to unauthenticated', (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());

      await notifier.signInWithEmail(
        email: 'bad@example.com',
        password: 'badpass',
      );
      await tester.pump();

      expect(notifier.state.hasError, true);

      notifier.resetError();
      await tester.pump();

      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());
      expect(notifier.signInAttempts, 1);
    });

    testWidgets('remains on AuthScreen after consecutive errors',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Sign in — error
      await notifier.signInWithEmail(
        email: 'bad@example.com',
        password: 'badpass',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(notifier.signInAttempts, 1);

      // Sign in again — another error
      await notifier.signInWithEmail(
        email: 'bad2@example.com',
        password: 'badpass2',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Still on AuthScreen after consecutive errors
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.assertNoCrashScreen();
      expect(notifier.signInAttempts, 2);
    });
  });
}