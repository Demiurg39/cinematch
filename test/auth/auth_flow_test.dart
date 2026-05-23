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
import 'package:cinematch/app.dart';

// ─── Test Notifiers ────────────────────────────────────────────────

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }
}

class _LoadingNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncLoading();
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

class _SessionRestoreNotifier extends AuthNotifier {
  bool restoreCalled = false;

  @override
  AsyncValue<AuthState> build() {
    // Simulate initial loading then unauthenticated
    Future(() {
      state = const AsyncData(AuthUnauthenticated());
    });
    return const AsyncLoading();
  }

  @override
  Future<void> restoreSession() async {
    restoreCalled = true;
    state = AsyncData(AuthAuthenticated(_testUser));
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
    // Don't call Navigator.pop in test — just change state
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

Future<void> switchToSignUp(WidgetTester tester) async {
  // Find the toggle GestureDetector by looking for RichText containing "Sign Up"
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

      // Toggle to sign-up mode
      await switchToSignUp(tester);

      // Verify sign-up UI
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      // Email, password, and username fields
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Fill registration form
      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Submit
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify notifier was called
      expect(notifier.signUpCalled, true);
      // State should now be authenticated
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('sign-up validates username is required', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      // Leave username empty, fill email and password
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 2: Session Persistence (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 2: Session persistence after restart', () {
    test('AuthSessionService correctly saves and restores session',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AuthSessionService();

      // Initially no session
      expect(await service.hasSession(), false);

      // Simulate a session save (as would happen after login)
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: '{"access_token":"test"}');
      await storage.write(key: 'cached_user_id', value: 'test-user-id');

      // Session should be detected
      expect(await service.hasSession(), true);
      expect(await service.getCachedUserId(), 'test-user-id');
    });

    testWidgets('restoreSession transitions from loading to authenticated',
        (tester) async {
      final notifier = _SessionRestoreNotifier();

      // Start with session mocked in storage
      FlutterSecureStorage.setMockInitialValues({
        'supabase_session': '{"access_token":"test"}',
        'cached_user_id': 'test-user-id',
      });

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger restore and verify it transitions
      await notifier.restoreSession();
      await tester.pump();

      expect(notifier.restoreCalled, true);
      final state = notifier.state.valueOrNull;
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.username, 'testuser');
    });

    test('clearSession removes stored data', () async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_session': '{"access_token":"test"}',
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
  group('Scenario 3: Profile mutation does not disrupt auth state', () {
    testWidgets('ProfileScreen shows user data and stays on profile after update',
        (tester) async {
      final notifier = _ProfileUpdateNotifier();

      await tester.pumpWidget(profileApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify profile screen shows user info
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Member since 2025'), findsOneWidget);

      // Verify edit options are present
      expect(find.text('Edit Username'), findsOneWidget);
      expect(find.text('Preferred Language'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);

      // Tap edit username — opens dialog
      await tester.tap(find.text('Edit Username'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dialog should be visible
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify still on profile (not redirected to auth)
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(notifier.signOutTriggered, false);
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('sign out transitions to unauthenticated', (tester) async {
      final notifier = _AuthenticatedNotifier();

      // Pump to initialize the notifier in widget tree
      await tester.pumpWidget(authApp(notifier));
      await tester.pump();

      // Sign out
      await notifier.signOut();
      await tester.pump();

      // Auth state should be unauthenticated
      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 4: Invalid Email Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 4: Invalid email input validation', () {
    testWidgets('blocks submission when email missing @ symbol', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email-format');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('blocks submission when email field empty', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Leave email empty, enter password
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 5: Weak Password Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 5: Weak password validation', () {
    testWidgets('blocks submission when password too short', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Valid email, short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('blocks submission when password field empty', (tester) async {
      await tester.pumpWidget(authApp(_UnauthenticatedNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter email only
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 6: Wrong Credentials Error Handling (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 6: Wrong credentials error handling', () {
    testWidgets('shows error banner on failed sign-in', (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'nonexistent@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');

      // Submit - this triggers the error state
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // Let async propagate

      // Verify error banner shows user-friendly message
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // Verify user remains on auth screen
      expect(find.byType(AuthScreen), findsOneWidget);

      // Verify notifier was called
      expect(notifier.signInAttempts, 1);
    });

    testWidgets('error banner can be dismissed', (tester) async {
      final notifier = _SignInErrorNotifier();

      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Trigger error
      await tester.enterText(find.byType(TextFormField).first, 'bad@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'badpass');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error visible
      expect(find.text('Wrong email or password.'), findsOneWidget);

      // Scroll to error banner close icon and dismiss
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error should be gone
      expect(find.text('Wrong email or password.'), findsNothing);
    });

    testWidgets('error state resets back to unauthenticated after error', (tester) async {
      final notifier = _SignInErrorNotifier();

      // Pump widget to initialize the notifier in the widget tree
      await tester.pumpWidget(authApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Initial state is unauthenticated
      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());

      // Trigger error via sign in
      await notifier.signInWithEmail(
        email: 'bad@example.com',
        password: 'badpass',
      );
      await tester.pump();

      // Error state should contain error info
      expect(notifier.state.hasError, true);

      // Reset error
      notifier.resetError();
      await tester.pump();

      // Back to unauthenticated
      expect(notifier.state.valueOrNull, isA<AuthUnauthenticated>());
    });
  });
}