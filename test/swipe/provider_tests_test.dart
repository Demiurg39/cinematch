import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/presentation/providers/swipe_provider.dart';

void main() {
  group('SwipeDeckState', () {
    test('creates with default values', () {
      final state = SwipeDeckState(
        movies: [],
        seenTmdbIds: {},
        isLoading: true,
      );

      expect(state.movies, isEmpty);
      expect(state.seenTmdbIds, isEmpty);
      expect(state.isLoading, true);
      expect(state.mlRecommendedTmdbIds, isEmpty);
    });

    test('creates with custom values', () {
      final state = SwipeDeckState(
        movies: [],
        seenTmdbIds: {1, 2, 3},
        isLoading: false,
        mlRecommendedTmdbIds: {4, 5},
      );

      expect(state.seenTmdbIds, {1, 2, 3});
      expect(state.isLoading, false);
      expect(state.mlRecommendedTmdbIds, {4, 5});
    });

    test('supports copy semantics via constructor', () {
      final original = SwipeDeckState(
        movies: [],
        seenTmdbIds: {1},
        isLoading: false,
      );

      final updated = SwipeDeckState(
        movies: [],
        seenTmdbIds: {1, 2},
        isLoading: false,
      );

      expect(original.seenTmdbIds, {1});
      expect(updated.seenTmdbIds, {1, 2});
    });

    test('isLoading transitions correctly', () {
      final loading = SwipeDeckState(
        movies: [],
        seenTmdbIds: {},
        isLoading: true,
      );
      expect(loading.isLoading, true);

      final loaded = SwipeDeckState(
        movies: [],
        seenTmdbIds: {},
        isLoading: false,
      );
      expect(loaded.isLoading, false);
    });
  });
}