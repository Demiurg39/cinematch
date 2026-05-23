import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cinematch/features/auth/presentation/auth_screen.dart';
import 'package:cinematch/features/auth/presentation/providers/auth_provider.dart';
import 'package:cinematch/features/auth/domain/auth_state.dart';
import 'package:cinematch/features/auth/domain/user_model.dart';
import 'package:cinematch/features/auth/data/auth_session_service.dart';
import 'package:cinematch/features/settings/presentation/profile_screen.dart';

// ─── Mock Notifiers ─────────────────────────────────────────────────

final _testUser = UserModel(
  id: 'test-user-id',
  username: 'testuser',
  preferredLanguage: 'en',
  region: 'US',
  createdAt: DateTime(2025, 1, 15),
);

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

class _EmptyAuthNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }
}

// ─── Helpers ────────────────────────────────────────────────────────

Widget createAuthApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: AuthScreen()),
  );
}

Widget createProfileApp(AuthNotifier notifier) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

/// Minimal app that mirrors CinematchApp routing without Supabase dependencies
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

extension WidgetTesterDefensive on WidgetTester {
  Future<void> assertFormInteractive() async {
    expect(find.byType(TextFormField).first, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  Future<void> assertNoCrashScreen() async {
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Error:'), findsNothing);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 1: New User Registration (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 1: New User Registration', () {
    testWidgets('register with valid credentials creates session',
        (tester) async {
      final notifier = _SignUpSuccessNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
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

    testWidgets('username field is required in sign-up mode', (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
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
  group('Scenario 2: Session Persistence After Restart', () {
    testWidgets('AuthSessionService save and restore session data',
        (_) async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AuthSessionService();

      expect(await service.hasSession(), false);

      final storage = FlutterSecureStorage();
      await storage.write(
        key: 'supabase_session',
        value: '{"access_token":"test_jwt","user":{"id":"test-user-id"}}',
      );
      await storage.write(key: 'cached_user_id', value: 'test-user-id');

      expect(await service.hasSession(), true);
      expect(await service.getCachedUserId(), 'test-user-id');
    });

    testWidgets('routing app bypasses auth screen when session restores',
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

    testWidgets('routing app shows auth screen when session restore fails',
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

    testWidgets('clearSession removes all stored data', (_) async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_session': '{"access_token":"test_jwt"}',
        'cached_user_id': 'test-user-id',
      });
      final service = AuthSessionService();

      await service.clearSession();

      expect(await service.hasSession(), false);
      expect(await service.getCachedUserId(), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 3: Profile Mutation Guard (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 3: Profile Mutation Does Not Disrupt Auth', () {
    testWidgets('profile screen shows user data without redirecting to auth',
        (tester) async {
      final notifier = _ProfileUpdateNotifier();

      await tester.pumpWidget(createProfileApp(notifier));
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
      final notifier = _ProfileUpdateNotifier();

      await tester.pumpWidget(createProfileApp(notifier));
      await tester.pump();

      await notifier.signOut();
      await tester.pump();

      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 4: Invalid Email Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 4: Invalid Email Input Validation', () {
    testWidgets('blocks submission when email missing @',
        (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid-email-format',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
      await tester.assertNoCrashScreen();
      await tester.assertFormInteractive();
    });

    testWidgets('blocks submission when email field empty', (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      await tester.assertNoCrashScreen();
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 5: Weak Password Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 5: Weak Password Validation', () {
    testWidgets('client-side blocks password shorter than 6 chars',
        (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        '123',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Must be at least 6 characters'), findsOneWidget);
      await tester.assertNoCrashScreen();
      await tester.assertFormInteractive();
    });

    testWidgets('client-side blocks empty password', (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('API weak-password error shows inline banner, no black screen',
        (tester) async {
      final notifier = _SignUpErrorNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      // Use password that passes client validation (>=6 chars) but fails API
      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'weakapi123');

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll to error banner at top of form
      await tester.ensureVisible(
        find.text('Password is too weak. Use 6+ characters.'),
      );
      await tester.pump();

      expect(find.text('Password is too weak. Use 6+ characters.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await tester.assertNoCrashScreen();
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.assertFormInteractive();
      expect(notifier.signUpAttempts, 1);
    });

    testWidgets('routing app shows AuthScreen on sign-up API error, not crash',
        (tester) async {
      final notifier = _SignUpErrorNotifier();

      await tester.pumpWidget(routingApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await notifier.signUpWithEmail(
        email: 'new@example.com',
        password: 'weakapi123',
        username: 'newuser',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Error:'), findsNothing);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 6: Wrong Credentials Error Handling (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 6: Wrong Credentials Error Handling', () {
    testWidgets('shows inline error banner on failed sign-in',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
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

      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      await tester.assertNoCrashScreen();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(notifier.signInAttempts, 1);
      await tester.assertFormInteractive();
    });

    testWidgets('routing app shows AuthScreen on sign-in API error',
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

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Error:'), findsNothing);
      expect(find.text('AUTHENTICATED_DASHBOARD'), findsNothing);
    });

    testWidgets('error banner dismissible, form reusable after dismiss',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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

      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Wrong email or password.'), findsNothing);
      await tester.assertFormInteractive();
    });

    testWidgets('error state resets back to unauthenticated',
        (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
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

      await tester.pumpWidget(createAuthApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await notifier.signInWithEmail(
        email: 'bad@example.com',
        password: 'badpass',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(notifier.signInAttempts, 1);

      await notifier.signInWithEmail(
        email: 'bad2@example.com',
        password: 'badpass2',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.assertNoCrashScreen();
      expect(notifier.signInAttempts, 2);
    });
  });
}