import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';
import 'match_provider.dart';
import 'genre_filter_provider.dart';

part 'swipe_provider.g.dart';

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  static const _prefetchThreshold = 10;
  static const _initialLoadSize = 30;

  // Track seen movie IDs to avoid duplicates
  final Set<int> _seenTmdbIds = {};

  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    // Load more initially - 30 movies for smooth experience
    final cached = await repository.getCachedMovies(limit: _initialLoadSize * 2);
    if (cached.isNotEmpty) {
      _markSeen(cached);
      cached.shuffle();
      return cached;
    }

    final movies = await repository.getPopularMovies();
    _markSeen(movies);
    movies.shuffle();
    return movies;
  }

  void _markSeen(List<MovieModel> movies) {
    for (final m in movies) {
      _seenTmdbIds.add(m.tmdbId);
    }
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
  }

  Future<void> _loadMoreInBackground() async {
    try {
      final repository = ref.read(moviesRepositoryProvider);
      final genreFilter = ref.read(genreFilterNotifierProvider);
      final currentDeck = state.valueOrNull ?? [];

      List<MovieModel> newMovies;
      final selectedGenres = genreFilter['selectedGenres'] as List<int>;

      if (selectedGenres.isNotEmpty) {
        // Fetch by genre filter
        newMovies = await repository.discoverMoviesByGenre(
          genreIds: selectedGenres,
          page: (currentDeck.length ~/ 20) + 1,
        );
      } else {
        // Fetch popular
        newMovies = await repository.getPopularMovies(
          page: (currentDeck.length ~/ 20) + 1,
        );
      }

      // Filter out already-seen movies
      newMovies = newMovies.where((m) => !_seenTmdbIds.contains(m.tmdbId)).toList();
      newMovies.shuffle();

      if (newMovies.isNotEmpty) {
        _markSeen(newMovies);
        state = AsyncData([...currentDeck, ...newMovies]);
      }
    } catch (_) {
      // Silently ignore load errors
    }
  }

  Future<void> loadMore() async {
    final repository = ref.read(moviesRepositoryProvider);
    final currentDeck = state.valueOrNull ?? [];
    final page = (currentDeck.length ~/ 20) + 1;
    final newMovies = await repository.getPopularMovies(page: page);

    // Filter out already-seen movies
    final filtered = newMovies.where((m) => !_seenTmdbIds.contains(m.tmdbId)).toList();
    filtered.shuffle();

    if (filtered.isNotEmpty) {
      _markSeen(filtered);
      state = AsyncData([...currentDeck, ...filtered]);
    }
  }

  int get seenCount => _seenTmdbIds.length;
}
