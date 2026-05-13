import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/swipe/domain/swipe_action.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';

abstract class SwipeRepositoryInterface {
  String? get currentUserId;
  Future<void> recordSwipe({
    required String userId,
    required MovieModel movie,
    required SwipeAction action,
  });
  Future<List<Map<String, dynamic>>> getSwipeActionsForMovie(int tmdbId);
  Future<List<Map<String, dynamic>>> getMatches();
  Stream<List<Map<String, dynamic>>> watchMatches(String userId);
}

class MockSwipeRepository implements SwipeRepositoryInterface {
  final List<Map<String, dynamic>> _swipes = [];
  final List<Map<String, dynamic>> _matches = [];

  @override
  String? get currentUserId => 'test-user-id';

  void addSwipe(Map<String, dynamic> swipe) => _swipes.add(swipe);
  void setMatches(List<Map<String, dynamic>> matches) => _matches.addAll(matches);

  @override
  Future<void> recordSwipe({
    required String userId,
    required MovieModel movie,
    required SwipeAction action,
  }) async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<List<Map<String, dynamic>>> getSwipeActionsForMovie(int tmdbId) async {
    return _swipes.where((s) => s['movie_tmdb_id'] == tmdbId).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getMatches() async {
    return _matches;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMatches(String userId) {
    return Stream.value(_matches.where((m) => m['user_id'] == userId).toList());
  }
}

void main() {
  group('SwipeRepository', () {
    test('recordSwipe inserts swipe record', () async {
      final repo = MockSwipeRepository();
      final movie = MovieModel(
        id: '',
        tmdbId: 123,
        title: 'Test Movie',
        year: 2024,
        posterUrl: 'https://example.com/poster.jpg',
        genres: const ['Action', 'Comedy'],
        cachedAt: DateTime.now(),
      );

      await repo.recordSwipe(
        userId: 'user-123',
        movie: movie,
        action: SwipeAction.like,
      );
    });

    test('getSwipeActionsForMovie returns likes for movie', () async {
      final repo = MockSwipeRepository();
      repo.addSwipe({'movie_tmdb_id': 123, 'user_id': 'user-1'});
      repo.addSwipe({'movie_tmdb_id': 123, 'user_id': 'user-2'});
      repo.addSwipe({'movie_tmdb_id': 456, 'user_id': 'user-1'});

      final result = await repo.getSwipeActionsForMovie(123);
      expect(result.length, 2);
    });

    test('getMatches returns match list', () async {
      final repo = MockSwipeRepository();
      repo.setMatches([
        {'id': '1', 'movie_id': 'movie-1', 'matched_user_id': 'user-2'},
        {'id': '2', 'movie_id': 'movie-2', 'matched_user_id': 'user-3'},
      ]);

      final matches = await repo.getMatches();
      expect(matches.length, 2);
    });

    test('watchMatches streams matches for user', () async {
      final repo = MockSwipeRepository();
      repo.setMatches([
        {'id': '1', 'user_id': 'test-user-id', 'movie_id': 'movie-1'},
        {'id': '2', 'user_id': 'other-user', 'movie_id': 'movie-2'},
      ]);

      await expectLater(
        repo.watchMatches('test-user-id'),
        emits(equals([
          {'id': '1', 'user_id': 'test-user-id', 'movie_id': 'movie-1'},
        ])),
      );
    });
  });

  group('SwipeAction', () {
    test('all swipe actions have correct names', () {
      expect(SwipeAction.like.name, 'like');
      expect(SwipeAction.dislike.name, 'dislike');
      expect(SwipeAction.maybe.name, 'maybe');
      expect(SwipeAction.veto.name, 'veto');
    });

    test('swipe actions are unique', () {
      final names = SwipeAction.values.map((e) => e.name).toSet();
      expect(names.length, SwipeAction.values.length);
    });
  });
}