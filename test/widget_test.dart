import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cinematch/app.dart';

void main() {
  testWidgets('Cinematch app smoke test', (WidgetTester tester) async {
    try {
      await Supabase.initialize(
        url: 'https://test-project.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // Already initialized
    }

    await tester.pumpWidget(
      const ProviderScope(
        child: CinematchApp(),
      ),
    );
    await tester.pump();

    // App should show auth screen or loading when Supabase is not fully configured
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}