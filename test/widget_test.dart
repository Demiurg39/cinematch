import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/app.dart';

void main() {
  testWidgets('Cinematch app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CinematchApp(),
      ),
    );
    expect(find.text('Cinematch'), findsOneWidget);
  });
}