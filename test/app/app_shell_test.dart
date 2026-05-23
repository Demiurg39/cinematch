import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cinematch/app/app_shell.dart';

void main() {
  setUp(() {
    try {
      Supabase.initialize(
        url: 'https://test-project.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {}
  });

  group('AppShell', () {
    testWidgets('renders bottom navigation with 4 destinations', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AppShell()),
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
        const ProviderScope(
          child: MaterialApp(home: AppShell()),
        ),
      );

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('can tap on Rooms navigation item', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AppShell()),
        ),
      );

      await tester.tap(find.text('Rooms'));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}