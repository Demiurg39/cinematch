import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/domain/swipe_action.dart';

void main() {
  group('SwipeAction', () {
    test('has correct values', () {
      expect(SwipeAction.values.length, 4);
      expect(SwipeAction.like.name, 'like');
      expect(SwipeAction.dislike.name, 'dislike');
      expect(SwipeAction.maybe.name, 'maybe');
      expect(SwipeAction.veto.name, 'veto');
    });

    test('all values are unique', () {
      final names = SwipeAction.values.map((e) => e.name).toSet();
      expect(names.length, SwipeAction.values.length);
    });
  });
}
