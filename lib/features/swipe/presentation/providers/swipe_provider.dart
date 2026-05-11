import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';
import 'match_provider.dart';

part 'swipe_provider.g.dart';

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  static const _prefetchThreshold = 10;
  static const _initialLoadSize = 30;

  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    // Load more initially - 30 movies for smooth experience
    final cached = await repository.getCachedMovies(limit: _initialLoadSize);
    if (cached.isNotEmpty) {
      cached.shuffle();
      return cached;
    }

    final movies = await repository.getPopularMovies();
    movies.shuffle();
    return movies;
  }

  Future<void> onSwipe(SwipeAction action, MovieModel movie) async {
    final currentDeck = state.valueOrNull ?? [];

    // Check for match when user likes
    if (action == SwipeAction.like) {
      _checkForMatch(movie);
    }

    // Optimistic update - remove card immediately for instant feedback
    final updatedDeck = currentDeck.where((m) => m.id != movie.id).toList();
    state = AsyncData(updatedDeck);

    // Record swipe in background
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ref.read(swipeRepositoryProvider).recordSwipe(
            userId: userId,
            movie: movie,
            action: action,
          ).catchError((_) {});
    }

    // Prefetch when getting low
    if (updatedDeck.length < _prefetchThreshold) {
      _loadMoreInBackground();
    }
  }

  Future<void> _checkForMatch(MovieModel movie) async {
    // TODO: Implement room-based match detection
    // For now, could trigger match celebration for personal likes
  }

  Future<void> _loadMoreInBackground() async {
    try {
      final repository = ref.read(moviesRepositoryProvider);
      final currentDeck = state.valueOrNull ?? [];
      // Fetch next page based on current deck size
      final page = (currentDeck.length ~/ 20) + 1;
      final newMovies = await repository.getPopularMovies(page: page);
      newMovies.shuffle();

      state = AsyncData([...currentDeck, ...newMovies]);
    } catch (_) {
      // Silently ignore load errors
    }
  }

  Future<void> loadMore() async {
    final repository = ref.read(moviesRepositoryProvider);
    final currentDeck = state.valueOrNull ?? [];
    final page = (currentDeck.length ~/ 20) + 1;
    final newMovies = await repository.getPopularMovies(page: page);
    newMovies.shuffle();
    state = AsyncData([...currentDeck, ...newMovies]);
  }
}
