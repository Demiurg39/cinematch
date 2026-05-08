import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/presentation/widgets/swipe_card.dart';

void main() {
  group('SwipeCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeCard(
              child: Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('calls onSwipeRight callback', (tester) async {
      bool swipedRight = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipeCard(
                onSwipeRight: () => swipedRight = true,
                child: Container(
                  width: 300,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(SwipeCard));
      await tester.dragFrom(center, const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(swipedRight, isTrue);
    });

    testWidgets('calls onSwipeLeft callback', (tester) async {
      bool swipedLeft = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipeCard(
                onSwipeLeft: () => swipedLeft = true,
                child: Container(
                  width: 300,
                  height: 400,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(SwipeCard));
      await tester.dragFrom(center, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(swipedLeft, isTrue);
    });
  });
}
