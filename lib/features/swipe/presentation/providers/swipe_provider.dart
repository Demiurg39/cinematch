import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';
import 'match_provider.dart';
import 'genre_filter_provider.dart';

part 'swipe_provider.g.dart';

@riverpod
SwipeDeckState swipeDeckState(SwipeDeckStateRef ref) {
  return SwipeDeckState(
    movies: [],
    seenTmdbIds: {},
    isLoading: true,
  );
}

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  static const _initialLoadSize = 60; // Start with more movies
  static const _prefetchThreshold = 45; // Prefetch when deck drops below this

  // Track page for infinite scroll per genre
  int _currentPage = 1;

  @override
  SwipeDeckState build() {
    // Listen for genre filter changes to trigger reload
    ref.listen(genreFilterNotifierProvider, (prev, next) {
      final prevGenres = (prev?['selectedGenres'] as List<int>?) ?? [];
      final nextGenres = (next['selectedGenres'] as List<int>?) ?? [];
      if (!_listEquals(prevGenres, nextGenres)) {
        Future.microtask(() => _onGenreChanged());
      }
    });

    // Initial load - fire and forget, don't wait
    Future.microtask(() => _initialize());

    return SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: true,
    );
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = List<int>.from(a)..sort();
    final sortedB = List<int>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  Future<void> _onGenreChanged() async {
    _currentPage = 1;
    state = SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: true,
    );
    await _initialize();
  }

  Future<void> _initialize() async {
    final repository = ref.read(moviesRepositoryProvider);
    final genreFilter = ref.read(genreFilterNotifierProvider);
    final selectedGenres = genreFilter['selectedGenres'] as List<int>;

    List<MovieModel> movies;

    if (selectedGenres.isNotEmpty) {
      // For genre filter, load more pages upfront since genre may have limited movies
      movies = await repository.discoverMoviesByGenre(
        genreIds: selectedGenres,
        page: _currentPage,
      );
      _currentPage++;

      // If empty, retry
      if (movies.isEmpty) {
        movies = await repository.discoverMoviesByGenre(
          genreIds: selectedGenres,
          page: _currentPage,
        );
        _currentPage++;
      }
    } else {
      final cached = await repository.getCachedMovies(limit: _initialLoadSize);
      if (cached.isNotEmpty) {
        cached.shuffle();

        state = SwipeDeckState(
          movies: cached,
          seenTmdbIds: {...state.seenTmdbIds, ...cached.map((m) => m.tmdbId).toSet()},
          isLoading: false,
        );

        _refreshMissingDetails(cached);
        _loadMoreInBackground();
        return;
      }
      movies = await repository.getPopularMovies(page: _currentPage);
      _currentPage++;
    }

    // Still empty? Try popular as fallback
    if (movies.isEmpty) {
      movies = await repository.getPopularMovies(page: _currentPage);
      _currentPage++;
    }

    movies.shuffle();

    state = SwipeDeckState(
      movies: movies,
      seenTmdbIds: {...state.seenTmdbIds, ...movies.map((m) => m.tmdbId).toSet()},
      isLoading: false,
    );

    _refreshMissingDetails(movies);
    _loadMoreInBackground();
  }

  Future<void> _refreshMissingDetails(List<MovieModel> movies) async {
    final repository = ref.read(moviesRepositoryProvider);

    // Find movies missing overview
    final needsRefresh = movies.where((m) => m.overview == null || m.overview!.isEmpty).toList();
    if (needsRefresh.isEmpty) return;

    final refreshed = await Future.wait(
      needsRefresh.map((m) => repository.refreshMovieDetails(m.tmdbId)),
    );

    final validRefreshed = refreshed.whereType<MovieModel>().toList();
    if (validRefreshed.isEmpty) return;

    // Build a map of tmdbId -> refreshed movie for quick lookup
    final refreshMap = {for (var r in validRefreshed) r.tmdbId: r};

    // Update state by merging refreshed movies with existing state
    final updatedMovies = state.movies.map((m) {
      final refreshed = refreshMap[m.tmdbId];
      return refreshed ?? m;
    }).toList();

    state = SwipeDeckState(
      movies: updatedMovies,
      seenTmdbIds: state.seenTmdbIds,
      isLoading: false,
    );
  }

  Future<void> onSwipe(SwipeAction action, MovieModel movie) async {
    final currentDeck = state.movies;

    if (action == SwipeAction.like) {
      _checkForMatch(movie);
    }

    // Use tmdbId only - id is empty for TMDB movies and only gets set on cache insert
    final updatedDeck = currentDeck.where((m) => m.tmdbId != movie.tmdbId).toList();
    final updatedSeen = {...state.seenTmdbIds, movie.tmdbId};

    state = SwipeDeckState(
      movies: updatedDeck,
      seenTmdbIds: updatedSeen,
      isLoading: false,
    );

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ref.read(swipeRepositoryProvider).recordSwipe(
            userId: userId,
            movie: movie,
            action: action,
          ).catchError((_) {});
    }

    // Only prefetch if deck is getting low - NOT on every swipe
    if (updatedDeck.length < _prefetchThreshold) {
      _loadMoreInBackground();
    }
  }

  Future<void> _checkForMatch(MovieModel movie) async {}

  Future<void> _loadMoreInBackground() async {
    // Silently prefetch - don't change isLoading to avoid UI flicker
    if (state.isLoading) return;
    if (state.movies.length >= _prefetchThreshold) return;

    try {
      final repository = ref.read(moviesRepositoryProvider);
      final genreFilter = ref.read(genreFilterNotifierProvider);
      final selectedGenres = genreFilter['selectedGenres'] as List<int>;

      List<MovieModel> newMovies;
      bool genreExhausted = false;

      if (selectedGenres.isNotEmpty) {
        newMovies = await repository.discoverMoviesByGenre(
          genreIds: selectedGenres,
          page: _currentPage,
        );
        _currentPage++;

        // If genre returns empty, it's exhausted
        if (newMovies.isEmpty) {
          genreExhausted = true;
        }
      } else {
        newMovies = await repository.getPopularMovies(page: _currentPage);
        _currentPage++;
      }

      // If empty, retry next page once
      if (newMovies.isEmpty) {
        if (selectedGenres.isNotEmpty && !genreExhausted) {
          newMovies = await repository.discoverMoviesByGenre(
            genreIds: selectedGenres,
            page: _currentPage,
          );
          _currentPage++;
          if (newMovies.isEmpty) genreExhausted = true;
        } else {
          newMovies = await repository.getPopularMovies(page: _currentPage);
          _currentPage++;
        }
      }

      // Still empty? If genre was exhausted, fall back to popular movies
      if (newMovies.isEmpty && genreExhausted) {
        newMovies = await repository.getPopularMovies(page: _currentPage);
        _currentPage++;
      }

      // Completely exhausted
      if (newMovies.isEmpty) return;

      // Filter seen only for non-genre (genre movies already filtered by TMDB)
      if (selectedGenres.isEmpty) {
        newMovies = newMovies.where((m) => !state.seenTmdbIds.contains(m.tmdbId)).toList();
      }
      newMovies.shuffle();

      // Fire and forget - update state without blocking
      _refreshMissingDetails(newMovies);

      if (newMovies.isNotEmpty) {
        final newSeen = {...state.seenTmdbIds, ...newMovies.map((m) => m.tmdbId).toSet()};
        state = SwipeDeckState(
          movies: [...state.movies, ...newMovies],
          seenTmdbIds: newSeen,
          isLoading: false,
        );
      }
    } catch (_) {
      // Silently ignore prefetch errors
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: true,
    );
    await _initialize();
  }
}

class SwipeDeckState {
  final List<MovieModel> movies;
  final Set<int> seenTmdbIds;
  final bool isLoading;

  SwipeDeckState({
    required this.movies,
    required this.seenTmdbIds,
    required this.isLoading,
  });
}
