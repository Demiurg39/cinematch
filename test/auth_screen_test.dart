import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematch/features/auth/presentation/auth_screen.dart';
import 'package:cinematch/features/auth/presentation/providers/auth_provider.dart';
import 'package:cinematch/features/auth/domain/auth_state.dart';

void main() {
  group('AuthScreen Widget Tests', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders Cinematch title and logo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.text('Cinematch'), findsOneWidget);
      expect(find.byIcon(Icons.movie_filter), findsOneWidget);
    });

    testWidgets('shows Sign In by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('No account? Sign Up'), findsOneWidget);
    });

    testWidgets('toggles to Sign Up mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      await tester.tap(find.text('No account? Sign Up'));
      await tester.pump();

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Already have account? Sign In'), findsOneWidget);
    });

    testWidgets('renders Google sign in button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('validates empty email', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('validates empty password', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates password length', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifier()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).last, '12345');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password must be 6+ chars'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => TestAuthNotifierLoading()),
          ],
          child: const MaterialApp(home: AuthScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class TestAuthNotifier extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncData(AuthUnauthenticated());
  }
}

class TestAuthNotifierLoading extends AuthNotifier {
  @override
  AsyncValue<AuthState> build() {
    return const AsyncLoading();
  }
}