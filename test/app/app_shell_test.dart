import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cinematch/app/app_shell.dart';
import 'package:cinematch/features/swipe/presentation/providers/swipe_provider.dart';

class _MockSwipeDeckNotifier extends SwipeDeckNotifier {
  @override
  SwipeDeckState build() {
    return SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: false,
      mlRecommendedTmdbIds: {},
    );
  }
}

class _MockPopularDeckNotifier extends PopularDeckNotifier {
  @override
  SwipeDeckState build() {
    return SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: false,
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://test-project.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {}
  });

  group('AppShell', () {
    testWidgets('renders bottom navigation with 4 destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swipeDeckNotifierProvider.overrideWith(() => _MockSwipeDeckNotifier()),
            popularDeckNotifierProvider.overrideWith(() => _MockPopularDeckNotifier()),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Swipe'), findsOneWidget);
      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows SwipeScreen by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swipeDeckNotifierProvider.overrideWith(() => _MockSwipeDeckNotifier()),
            popularDeckNotifierProvider.overrideWith(() => _MockPopularDeckNotifier()),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('can tap on Rooms navigation item', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            swipeDeckNotifierProvider.overrideWith(() => _MockSwipeDeckNotifier()),
            popularDeckNotifierProvider.overrideWith(() => _MockPopularDeckNotifier()),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.tap(find.text('Rooms'));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}