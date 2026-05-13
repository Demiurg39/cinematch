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
    mlRecommendedTmdbIds: {},
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
      mlRecommendedTmdbIds: {},
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
      mlRecommendedTmdbIds: {},
    );
    await _initialize();
  }

  Future<void> _initialize() async {
    final repository = ref.read(moviesRepositoryProvider);
    final genreFilter = ref.read(genreFilterNotifierProvider);
    final selectedGenres = genreFilter['selectedGenres'] as List<int>;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    List<MovieModel> movies = [];
    List<MovieModel> mlMovies = [];

    if (selectedGenres.isNotEmpty) {
      // Try ML first with genre filter (personalized + genre-matched)
      if (userId != null) {
        mlMovies = await repository.getRecommendedMovies(userId: userId, limit: _initialLoadSize);
        if (mlMovies.isNotEmpty) {
          // Filter ML results by selected genres client-side
          movies = mlMovies.where((m) {
            return m.genres.any((g) => selectedGenres.contains(_genreNameToId(g)));
          }).toList();
        }
      }

      // Fall back to TMDB discover if ML didn't return genre-matched movies
      if (movies.isEmpty) {
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
      }
    } else if (userId != null) {
      // Try ML recommendations first if user has history
      mlMovies = await repository.getRecommendedMovies(userId: userId, limit: _initialLoadSize);

      if (mlMovies.isNotEmpty) {
        movies = mlMovies;
      } else {
        // Cold start - no ML data yet, fall back to cached/popular
        final cached = await repository.getCachedMovies(limit: _initialLoadSize);
        if (cached.isNotEmpty) {
          cached.shuffle();
          state = SwipeDeckState(
            movies: cached,
            seenTmdbIds: {...state.seenTmdbIds, ...cached.map((m) => m.tmdbId).toSet()},
            isLoading: false,
            mlRecommendedTmdbIds: {},
          );
          _refreshMissingDetails(cached);
          _loadMoreInBackground();
          return;
        }
        movies = await repository.getPopularMovies(page: _currentPage);
        _currentPage++;
      }
    } else {
      // No userId - use popular movies
      final cached = await repository.getCachedMovies(limit: _initialLoadSize);
      if (cached.isNotEmpty) {
        cached.shuffle();
        state = SwipeDeckState(
          movies: cached,
          seenTmdbIds: {...state.seenTmdbIds, ...cached.map((m) => m.tmdbId).toSet()},
          isLoading: false,
          mlRecommendedTmdbIds: {},
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

    // Track which movies came from ML recommendations
    final mlTmdbIds = mlMovies.map((m) => m.tmdbId).toSet();

    state = SwipeDeckState(
      movies: movies,
      seenTmdbIds: {...state.seenTmdbIds, ...movies.map((m) => m.tmdbId).toSet()},
      isLoading: false,
      mlRecommendedTmdbIds: mlTmdbIds,
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
      mlRecommendedTmdbIds: state.mlRecommendedTmdbIds,
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
      mlRecommendedTmdbIds: state.mlRecommendedTmdbIds.where((id) => id != movie.tmdbId).toSet(),
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
      final userId = Supabase.instance.client.auth.currentUser?.id;

      List<MovieModel> newMovies = [];
      bool genreExhausted = false;
      final newMlTmdbIds = <int>{};
      List<MovieModel> mlMovies = [];

      if (selectedGenres.isNotEmpty) {
        // Try ML first even with genre filter (personalized + genre-matched)
        if (userId != null) {
          mlMovies = await repository.getRecommendedMovies(userId: userId, limit: 30);
          if (mlMovies.isNotEmpty) {
            // Filter ML results by selected genres client-side
            newMovies = mlMovies.where((m) {
              return m.genres.any((g) => selectedGenres.contains(_genreNameToId(g)));
            }).toList();
            newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
          }
        }

        // If ML didn't return genre-matched movies, use TMDB discover
        if (newMovies.isEmpty) {
          newMovies = await repository.discoverMoviesByGenre(
            genreIds: selectedGenres,
            page: _currentPage,
          );
          _currentPage++;
          if (newMovies.isEmpty) {
            genreExhausted = true;
          }
        }
      } else if (userId != null) {
        // Try ML recommendations for logged-in users
        mlMovies = await repository.getRecommendedMovies(userId: userId, limit: 30);
        if (mlMovies.isNotEmpty) {
          newMovies = mlMovies;
          newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
        } else {
          // Fall back to popular
          newMovies = await repository.getPopularMovies(page: _currentPage);
          _currentPage++;
        }
      } else {
        // No user - use popular
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
          mlRecommendedTmdbIds: {...state.mlRecommendedTmdbIds, ...newMlTmdbIds},
        );
      }
    } catch (_) {
      // Silently ignore prefetch errors
    }
  }

  int _genreNameToId(String genreName) {
    const genreMap = {
      'Action': 28,
      'Adventure': 12,
      'Animation': 16,
      'Comedy': 35,
      'Crime': 80,
      'Documentary': 99,
      'Drama': 18,
      'Family': 10751,
      'Fantasy': 14,
      'History': 36,
      'Horror': 27,
      'Music': 10402,
      'Mystery': 9648,
      'Romance': 10749,
      'Science Fiction': 878,
      'TV Movie': 10770,
      'Thriller': 53,
      'War': 10752,
      'Western': 37,
    };
    return genreMap[genreName] ?? 0;
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: true,
      mlRecommendedTmdbIds: {},
    );
    await _initialize();
  }
}

class SwipeDeckState {
  final List<MovieModel> movies;
  final Set<int> seenTmdbIds;
  final bool isLoading;
  final Set<int> mlRecommendedTmdbIds;

  SwipeDeckState({
    required this.movies,
    required this.seenTmdbIds,
    required this.isLoading,
    this.mlRecommendedTmdbIds = const {},
  });
}
