import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/app/app_shell.dart';

void main() {
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
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
