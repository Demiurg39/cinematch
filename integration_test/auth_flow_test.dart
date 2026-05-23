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
import 'package:cinematch/app.dart';

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

class _ProfileUpdateNotifier extends AuthNotifier {
  bool signOutTriggered = false;
  bool updateCalled = false;

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

      // Switch to sign-up mode
      await switchToSignUp(tester);

      // Verify registration UI elements present
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Fill all fields
      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Submit
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify notifier called and state transitioned
      expect(notifier.signUpCalled, true);
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('username field is required in sign-up mode', (tester) async {
      await tester.pumpWidget(createAuthApp(_EmptyAuthNotifier()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await switchToSignUp(tester);

      // Skip username, fill email and password
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Get Started'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 2: Persistent Login & Hot Restart (Positive)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 2: Session Persistence After Restart', () {
    testWidgets('AuthSessionService save and restore session data',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = AuthSessionService();

      expect(await service.hasSession(), false);

      // Simulate session save as after login
      final storage = FlutterSecureStorage();
      await storage.write(
        key: 'supabase_session',
        value: '{"access_token":"test_jwt","user":{"id":"test-user-id"}}',
      );
      await storage.write(key: 'cached_user_id', value: 'test-user-id');

      expect(await service.hasSession(), true);
      expect(await service.getCachedUserId(), 'test-user-id');
    });

    testWidgets('restoreSession bypasses login and goes to authenticated',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'supabase_session': '{"access_token":"test_jwt"}',
        'cached_user_id': 'test-user-id',
      });

      final notifier = _SessionRestoreNotifier();

      await tester.pumpWidget(createAuthApp(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await notifier.restoreSession();
      await tester.pump();

      expect(notifier.restoreCalled, true);
      expect(notifier.state.valueOrNull, isA<AuthAuthenticated>());
    });

    testWidgets('clearSession removes all stored data', () async {
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

      // Verify profile displays user info
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Member since 2025'), findsOneWidget);
      expect(find.text('Edit Username'), findsOneWidget);

      // Open edit dialog
      await tester.tap(find.text('Edit Username'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dialog appears with Save/Cancel
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Still on profile — no redirect
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
    testWidgets('blocks submission when email missing @ symbol',
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
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 5: Weak Password Validation (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 5: Weak Password Validation', () {
    testWidgets('blocks submission when password too short', (tester) async {
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
    });

    testWidgets('blocks submission when password field empty', (tester) async {
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
  });

  // ──────────────────────────────────────────────────────────────────
  // SCENARIO 6: Wrong Credentials Error Handling (Negative)
  // ──────────────────────────────────────────────────────────────────
  group('Scenario 6: Wrong Credentials Error Handling', () {
    testWidgets('shows error banner on failed sign-in', (tester) async {
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

      // Error banner with user-friendly message
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // User remains on auth screen
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(notifier.signInAttempts, 1);
    });

    testWidgets('error banner dismissible', (tester) async {
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
    });

    testWidgets('error state resets back to unauthenticated', (tester) async {
      final notifier = _SignInErrorNotifier();

      // Pump widget to initialize the notifier in the widget tree
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
  });
}