import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/localization/user_locale_provider.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';
import '../../data/swipe_repository.dart';
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
  static const _initialLoadSize = 60;
  static const _prefetchThreshold = 45;

  int _currentPage = 1;
  String? _currentRoomId;

  void setRoomId(String? roomId) {
    _currentRoomId = roomId;
  }

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

    // Listen for locale changes to refresh content
    ref.listen(userLocaleProvider, (prev, next) {
      if (prev?.languageTag != next.languageTag) {
        Future.microtask(() => refresh());
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
    final locale = ref.read(userLocaleProvider);

    List<MovieModel> movies = [];
    List<MovieModel> mlMovies = [];

    if (selectedGenres.isNotEmpty) {
      // Try vector recs first (pgvector-based, most personalized)
      if (userId != null) {
        mlMovies = await repository.getVectorRecommendations(userId: userId, limit: _initialLoadSize);
        if (mlMovies.isNotEmpty) {
          movies = mlMovies.where((m) {
            return m.genres.any((g) => selectedGenres.contains(_genreNameToId(g)));
          }).toList();
        }
      }

      // Fall back to existing ML recs (RPC-based)
      if (movies.isEmpty && userId != null) {
        mlMovies = await repository.getRecommendedMovies(userId: userId, limit: _initialLoadSize);
        if (mlMovies.isNotEmpty) {
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
          language: locale.language,
          region: locale.region,
        );
        _currentPage++;

        if (movies.isEmpty) {
          movies = await repository.discoverMoviesByGenre(
            genreIds: selectedGenres,
            page: _currentPage,
            language: locale.language,
            region: locale.region,
          );
          _currentPage++;
        }
      }
    } else if (userId != null) {
      // Try vector recs first (pgvector-based)
      mlMovies = await repository.getVectorRecommendations(userId: userId, limit: _initialLoadSize);

      if (mlMovies.isEmpty) {
        // Fall back to existing ML recs (RPC-based)
        mlMovies = await repository.getRecommendedMovies(userId: userId, limit: _initialLoadSize);
      }

      if (mlMovies.isNotEmpty) {
        movies = mlMovies;
      } else {
        // No ML data - use popular movies directly
        movies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
        _currentPage++;
      }
    } else {
      // No userId - use popular movies
      movies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
      _currentPage++;
    }

    // Still empty? Try popular as fallback
    if (movies.isEmpty) {
      movies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
      _currentPage++;
    }

    movies.shuffle();

    // Track which movies came from ML recommendations
    // Badge shows for any ML-returned movie (even cold-start users get ML recommendations)
    Set<int> mlTmdbIds = {};
    if (mlMovies.isNotEmpty) {
      mlTmdbIds = mlMovies.map((m) => m.tmdbId).toSet();
    }

    state = SwipeDeckState(
      movies: movies,
      seenTmdbIds: {...state.seenTmdbIds, ...movies.map((m) => m.tmdbId).toSet()},
      isLoading: false,
      mlRecommendedTmdbIds: mlTmdbIds,
    );

    _loadMoreInBackground();
  }

  Future<void> onSwipe(SwipeAction action, MovieModel movie) async {
    final currentDeck = state.movies;

    final updatedDeck = currentDeck.where((m) => m.tmdbId != movie.tmdbId).toList();
    final updatedSeen = {...state.seenTmdbIds, movie.tmdbId};

    state = SwipeDeckState(
      movies: updatedDeck,
      seenTmdbIds: updatedSeen,
      isLoading: false,
      mlRecommendedTmdbIds: state.mlRecommendedTmdbIds.where((id) => id != movie.tmdbId).toSet(),
      partnerLikedTmdbIds: state.partnerLikedTmdbIds,
    );

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ref.read(swipeRepositoryProvider).recordSwipe(
            userId: userId,
            movie: movie,
            action: action,
            roomId: _currentRoomId,
          ).catchError((_) {});
    }

    if (action == SwipeAction.like) {
      await _checkForMatch(movie);
    }

    if (updatedDeck.length < _prefetchThreshold) {
      _loadMoreInBackground();
    }
  }

  void setPartnerLikedTmdbIds(Set<int> tmdbIds) {
    state = SwipeDeckState(
      movies: state.movies,
      seenTmdbIds: state.seenTmdbIds,
      isLoading: state.isLoading,
      mlRecommendedTmdbIds: state.mlRecommendedTmdbIds,
      partnerLikedTmdbIds: tmdbIds,
    );
  }

  Future<bool> _checkForMatch(MovieModel movie) async {
    if (_currentRoomId == null) return false;

    final repo = ref.read(swipeRepositoryProvider);

    String? movieDbId = movie.id.isEmpty ? null : movie.id;
    if (movieDbId == null) {
      final client = Supabase.instance.client;
      final cached = await client.from('movies').select('id').eq('tmdb_id', movie.tmdbId).maybeSingle();
      movieDbId = cached?['id'] as String?;
    }
    if (movieDbId == null) return false;

    return repo.checkUnanimousMatch(_currentRoomId!, movieDbId);
  }

  Future<void> _loadMoreInBackground() async {
    // Silently prefetch - don't change isLoading to avoid UI flicker
    if (state.isLoading) return;
    if (state.movies.length >= _prefetchThreshold) return;

    try {
      final repository = ref.read(moviesRepositoryProvider);
      final genreFilter = ref.read(genreFilterNotifierProvider);
      final selectedGenres = genreFilter['selectedGenres'] as List<int>;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final locale = ref.read(userLocaleProvider);

      List<MovieModel> newMovies = [];
      bool genreExhausted = false;
      final newMlTmdbIds = <int>{};
      List<MovieModel> mlMovies = [];

      if (selectedGenres.isNotEmpty) {
        // Try vector recs first
        if (userId != null) {
          mlMovies = await repository.getVectorRecommendations(userId: userId, limit: 30);
          if (mlMovies.isNotEmpty) {
            newMovies = mlMovies.where((m) {
              return m.genres.any((g) => selectedGenres.contains(_genreNameToId(g)));
            }).toList();
            newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
          }
        }

        // Fall back to existing ML recs
        if (newMovies.isEmpty && userId != null) {
          mlMovies = await repository.getRecommendedMovies(userId: userId, limit: 30);
          if (mlMovies.isNotEmpty) {
            newMovies = mlMovies.where((m) {
              return m.genres.any((g) => selectedGenres.contains(_genreNameToId(g)));
            }).toList();
            newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
          }
        }

        // If ML didn't return genre-matched movies, use TMDB discover
        if (newMovies.isEmpty) {
          newMlTmdbIds.clear();
          newMovies = await repository.discoverMoviesByGenre(
            genreIds: selectedGenres,
            page: _currentPage,
            language: locale.language,
            region: locale.region,
          );
          _currentPage++;
          if (newMovies.isEmpty) {
            genreExhausted = true;
          }
        }
      } else if (userId != null) {
        // Try vector recs first
        mlMovies = await repository.getVectorRecommendations(userId: userId, limit: 30);
        if (mlMovies.isNotEmpty) {
          newMovies = mlMovies;
          newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
        } else {
          // Fall back to existing ML recs
          mlMovies = await repository.getRecommendedMovies(userId: userId, limit: 30);
          if (mlMovies.isNotEmpty) {
            newMovies = mlMovies;
            newMlTmdbIds.addAll(mlMovies.map((m) => m.tmdbId));
          } else {
            // Fall back to popular
            newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
            _currentPage++;
          }
        }
      } else {
        // No user - use popular
        newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
        _currentPage++;
      }

      // If empty, retry next page once
      if (newMovies.isEmpty) {
        if (selectedGenres.isNotEmpty && !genreExhausted) {
          newMovies = await repository.discoverMoviesByGenre(
            genreIds: selectedGenres,
            page: _currentPage,
            language: locale.language,
            region: locale.region,
          );
          _currentPage++;
          if (newMovies.isEmpty) genreExhausted = true;
        } else {
          newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
          _currentPage++;
        }
      }

      // Still empty? If genre was exhausted, fall back to popular movies
      if (newMovies.isEmpty && genreExhausted) {
        newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
        _currentPage++;
      }

      // Completely exhausted
      if (newMovies.isEmpty) return;

      newMovies.shuffle();

      if (newMovies.isNotEmpty) {
        final newSeen = {...state.seenTmdbIds, ...newMovies.map((m) => m.tmdbId).toSet()};
        state = SwipeDeckState(
          movies: [...state.movies, ...newMovies],
          seenTmdbIds: newSeen,
          isLoading: false,
          mlRecommendedTmdbIds: {...state.mlRecommendedTmdbIds, ...newMlTmdbIds},
          partnerLikedTmdbIds: state.partnerLikedTmdbIds,
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

@riverpod
class PopularDeckNotifier extends _$PopularDeckNotifier {
  int _currentPage = 1;
  String? _currentRoomId;

  void setRoomId(String? roomId) {
    _currentRoomId = roomId;
  }

  @override
  SwipeDeckState build() {
    ref.listen(genreFilterNotifierProvider, (prev, next) {
      final prevGenres = (prev?['selectedGenres'] as List<int>?) ?? [];
      final nextGenres = (next['selectedGenres'] as List<int>?) ?? [];
      if (!_listEquals(prevGenres, nextGenres)) {
        Future.microtask(() => _onGenreChanged());
      }
    });

    ref.listen(userLocaleProvider, (prev, next) {
      if (prev?.languageTag != next.languageTag) {
        Future.microtask(() => refresh());
      }
    });

    Future.microtask(() => _load());

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
    await _load();
  }

  Future<void> _load() async {
    final repository = ref.read(moviesRepositoryProvider);
    final genreFilter = ref.read(genreFilterNotifierProvider);
    final selectedGenres = genreFilter['selectedGenres'] as List<int>;
    final locale = ref.read(userLocaleProvider);

    List<MovieModel> movies = [];

    if (selectedGenres.isNotEmpty) {
      movies = await repository.discoverMoviesByGenre(
        genreIds: selectedGenres,
        page: _currentPage,
        language: locale.language,
        region: locale.region,
      );
      _currentPage++;
    } else {
      movies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
      _currentPage++;
    }

    if (movies.isEmpty) {
      movies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
      _currentPage++;
    }

    movies.shuffle();

    state = SwipeDeckState(
      movies: movies,
      seenTmdbIds: {...movies.map((m) => m.tmdbId).toSet()},
      isLoading: false,
    );
  }

  Future<void> onSwipe(SwipeAction action, MovieModel movie) async {
    final currentDeck = state.movies;
    final updatedDeck = currentDeck.where((m) => m.tmdbId != movie.tmdbId).toList();
    final updatedSeen = {...state.seenTmdbIds, movie.tmdbId};

    state = SwipeDeckState(
      movies: updatedDeck,
      seenTmdbIds: updatedSeen,
      isLoading: false,
      partnerLikedTmdbIds: state.partnerLikedTmdbIds,
    );

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ref.read(swipeRepositoryProvider).recordSwipe(
        userId: userId,
        movie: movie,
        action: action,
        roomId: _currentRoomId,
      ).catchError((_) {});
    }

    if (updatedDeck.length < 45) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (state.isLoading) return;
    if (state.movies.length >= 45) return;

    try {
      final repository = ref.read(moviesRepositoryProvider);
      final genreFilter = ref.read(genreFilterNotifierProvider);
      final selectedGenres = genreFilter['selectedGenres'] as List<int>;
      final locale = ref.read(userLocaleProvider);

      List<MovieModel> newMovies = [];

      if (selectedGenres.isNotEmpty) {
        newMovies = await repository.discoverMoviesByGenre(
          genreIds: selectedGenres,
          page: _currentPage,
          language: locale.language,
          region: locale.region,
        );
        _currentPage++;
      } else {
        newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
        _currentPage++;
      }

      if (newMovies.isEmpty) {
        newMovies = await repository.getPopularMovies(page: _currentPage, language: locale.language, region: locale.region);
        _currentPage++;
      }

      if (newMovies.isEmpty) return;

      newMovies.shuffle();

      final newSeen = {...state.seenTmdbIds, ...newMovies.map((m) => m.tmdbId).toSet()};
      state = SwipeDeckState(
        movies: [...state.movies, ...newMovies],
        seenTmdbIds: newSeen,
        isLoading: false,
        partnerLikedTmdbIds: state.partnerLikedTmdbIds,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = SwipeDeckState(
      movies: [],
      seenTmdbIds: {},
      isLoading: true,
    );
    await _load();
  }
}

class SwipeDeckState {
  final List<MovieModel> movies;
  final Set<int> seenTmdbIds;
  final bool isLoading;
  final Set<int> mlRecommendedTmdbIds;
  final Set<int> partnerLikedTmdbIds;

  SwipeDeckState({
    required this.movies,
    required this.seenTmdbIds,
    required this.isLoading,
    this.mlRecommendedTmdbIds = const {},
    this.partnerLikedTmdbIds = const {},
  });
}
