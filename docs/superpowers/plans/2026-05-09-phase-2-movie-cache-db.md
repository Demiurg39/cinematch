# Cinematch Phase 2: Movie Cache DB

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** TMDB API integration, movie model, repository, and Riverpod providers for movie data with local caching.

**Architecture:** Clean Architecture. TMDB API client wraps HTTP calls. MoviesRepository handles data operations. MoviesProvider exposes state via Riverpod. Movies cached in Supabase `movies` table.

**Tech Stack:** dio (HTTP client), riverpod_annotation, freezed_annotation, supabase_flutter

---

## File Structure

```
lib/
├── core/
│   └── tmdb/
│       └── tmdb_api_client.dart      # TMDB HTTP client
├── features/
│   └── movies/
│       ├── data/
│       │   └── movies_repository.dart # Movie data operations
│       ├── domain/
│       │   └── movie_model.dart      # Movie model
│       └── presentation/
│           └── providers/
│               └── movies_provider.dart # Riverpod providers
```

---

## Tasks

### Task 1: TMDB API Client

**Files:**
- Create: `lib/core/tmdb/tmdb_api_client.dart`
- Create: `lib/core/tmdb/tmdb_endpoints.dart`

- [ ] **Step 1: Create tmdb_endpoints.dart**

```dart
class TmdbEndpoints {
  TmdbEndpoints._();

  static const String popularMovies = '/movie/popular';
  static const String searchMovies = '/search/movie';
  static const String movieDetails = '/movie';
  static const String watchProviders = '/movie/{movie_id}/watch/providers';
  static const String genreList = '/genre/movie/list';

  static String movieDetail(int movieId) => '/movie/$movieId';
  static String movieWatchProviders(int movieId) => '/movie/$movieId/watch/providers';
}
```

- [ ] **Step 2: Create tmdb_api_client.dart**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constants/app_constants.dart';

class TmdbApiClient {
  TmdbApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = 'https://api.themoviedb.org/3';
    _dio.options.queryParameters = {
      'api_key': AppConstants.tmdbApiKey,
    };
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getPopularMovies({
    int page = 1,
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.popularMovies,
      queryParameters: {
        'page': page,
        'language': language,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.searchMovies,
      queryParameters: {
        'query': query,
        'page': page,
        'language': language,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetails({
    required int tmdbId,
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.movieDetail(tmdbId),
      queryParameters: {'language': language},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWatchProviders({
    required int tmdbId,
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.movieWatchProviders(tmdbId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGenreList({
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.genreList,
      queryParameters: {'language': language},
    );
    return response.data as Map<String, dynamic>;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/tmdb/tmdb_api_client.dart lib/core/tmdb/tmdb_endpoints.dart && git commit -m "feat: add TMDB API client"
```

---

### Task 2: Movie Model

**Files:**
- Create: `lib/features/movies/domain/movie_model.dart`

- [ ] **Step 1: Create movie_model.dart**

```dart
class MovieModel {
  final String id;
  final int tmdbId;
  final String title;
  final int? year;
  final String? posterUrl;
  final List<String> genres;
  final double popularity;
  final int? runtime;
  final DateTime cachedAt;
  final DateTime? lastSyncedAt;

  const MovieModel({
    required this.id,
    required this.tmdbId,
    required this.title,
    this.year,
    this.posterUrl,
    this.genres = const [],
    this.popularity = 0,
    this.runtime,
    required this.cachedAt,
    this.lastSyncedAt,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as String,
      tmdbId: json['tmdb_id'] as int,
      title: json['title'] as String,
      year: json['year'] as int?,
      posterUrl: json['poster_url'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: json['runtime'] as int?,
      cachedAt: DateTime.parse(json['cached_at'] as String),
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'title': title,
      'year': year,
      'poster_url': posterUrl,
      'genres': genres,
      'popularity': popularity,
      'runtime': runtime,
      'cached_at': cachedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  factory MovieModel.fromTmdb(Map<String, dynamic> json) {
    final releaseDate = json['release_date'] as String?;
    return MovieModel(
      id: '', // Will be set by Supabase
      tmdbId: json['id'] as int,
      title: json['title'] as String,
      year: releaseDate != null && releaseDate.isNotEmpty
          ? int.tryParse(releaseDate.split('-').first)
          : null,
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      genres: [], // Populated separately
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: json['runtime'] as int?,
      cachedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/movies/domain/movie_model.dart && git commit -m "feat: add MovieModel"
```

---

### Task 3: Movies Repository

**Files:**
- Create: `lib/features/movies/data/movies_repository.dart`

- [ ] **Step 1: Create movies_repository.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/tmdb/tmdb_api_client.dart';
import '../domain/movie_model.dart';

class MoviesRepository {
  MoviesRepository({
    SupabaseClient? supabase,
    TmdbApiClient? tmdbApi,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _tmdbApi = tmdbApi ?? TmdbApiClient();

  final SupabaseClient _supabase;
  final TmdbApiClient _tmdbApi;

  Future<List<MovieModel>> getPopularMovies({int page = 1}) async {
    final data = await _tmdbApi.getPopularMovies(page: page);
    final results = data['results'] as List<dynamic>;

    final movies = <MovieModel>[];
    for (final json in results) {
      final movie = MovieModel.fromTmdb(json as Map<String, dynamic>);
      movies.add(movie);
    }

    // Cache movies in Supabase
    await _cacheMovies(movies);

    return movies;
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    final data = await _tmdbApi.searchMovies(query: query);
    final results = data['results'] as List<dynamic>;

    final movies = <MovieModel>[];
    for (final json in results) {
      final movie = MovieModel.fromTmdb(json as Map<String, dynamic>);
      movies.add(movie);
    }

    return movies;
  }

  Future<MovieModel?> getMovieByTmdbId(int tmdbId) async {
    final response = await _supabase
        .from('movies')
        .select()
        .eq('tmdb_id', tmdbId)
        .maybeSingle();

    if (response == null) return null;
    return MovieModel.fromJson(response);
  }

  Future<Map<String, dynamic>?> getWatchProviders(int tmdbId) async {
    return await _tmdbApi.getWatchProviders(tmdbId: tmdbId);
  }

  Future<void> _cacheMovies(List<MovieModel> movies) async {
    for (final movie in movies) {
      await _supabase.from('movies').upsert(
        {
          'tmdb_id': movie.tmdbId,
          'title': movie.title,
          'year': movie.year,
          'poster_url': movie.posterUrl,
          'genres': movie.genres,
          'popularity': movie.popularity,
          'runtime': movie.runtime,
          'cached_at': DateTime.now().toIso8601String(),
          'last_synced_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'tmdb_id',
      );
    }
  }

  Future<List<MovieModel>> getCachedMovies({int limit = 50}) async {
    final response = await _supabase
        .from('movies')
        .select()
        .order('popularity', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<MovieModel>> getMoviesByGenre(String genre) async {
    final response = await _supabase
        .from('movies')
        .select()
        .contains('genres', [genre])
        .order('popularity', ascending: false);

    return (response as List<dynamic>)
        .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/movies/data/movies_repository.dart && git commit -m "feat: add MoviesRepository with TMDB integration"
```

---

### Task 4: Movies Provider

**Files:**
- Create: `lib/features/movies/presentation/providers/movies_provider.dart`

- [ ] **Step 1: Create movies_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/movies_repository.dart';
import '../../domain/movie_model.dart';

part 'movies_provider.g.dart';

@riverpod
MoviesRepository moviesRepository(MoviesRepositoryRef ref) {
  return MoviesRepository();
}

@riverpod
class PopularMoviesNotifier extends _$PopularMoviesNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getPopularMovies();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(moviesRepositoryProvider);
      return repository.getPopularMovies();
    });
  }

  Future<void> loadMore(int page) async {
    final currentMovies = state.valueOrNull ?? [];
    final newMovies = await ref.read(moviesRepositoryProvider).getPopularMovies(page: page);
    state = AsyncData([...currentMovies, ...newMovies]);
  }
}

@riverpod
class MovieSearchNotifier extends _$MovieSearchNotifier {
  @override
  Future<List<MovieModel>> build() async {
    return [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(moviesRepositoryProvider);
      return repository.searchMovies(query);
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}

@riverpod
class CachedMoviesNotifier extends _$CachedMoviesNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getCachedMovies();
  }
}

@riverpod
class WatchProvidersNotifier extends _$WatchProvidersNotifier {
  @override
  Future<Map<String, dynamic>?> build(int tmdbId) async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getWatchProviders(tmdbId);
  }
}
```

- [ ] **Step 2: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates movies_provider.g.dart

- [ ] **Step 3: Commit**

```bash
git add lib/features/movies/presentation/providers/movies_provider.dart lib/features/movies/presentation/providers/movies_provider.g.dart && git commit -m "feat: add MoviesProvider with Riverpod"
```

---

### Task 5: Movies Feature Tests

**Files:**
- Create: `test/movies/movies_provider_test.dart`

- [ ] **Step 1: Create movies_provider_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';

void main() {
  group('MovieModel', () {
    test('fromJson creates MovieModel correctly', () {
      final json = {
        'id': '123',
        'tmdb_id': 456,
        'title': 'Test Movie',
        'year': 2024,
        'poster_url': 'https://example.com/poster.jpg',
        'genres': ['Action', 'Drama'],
        'popularity': 8.5,
        'runtime': 120,
        'cached_at': '2024-01-01T00:00:00.000Z',
        'last_synced_at': '2024-01-01T00:00:00.000Z',
      };

      final movie = MovieModel.fromJson(json);

      expect(movie.id, '123');
      expect(movie.tmdbId, 456);
      expect(movie.title, 'Test Movie');
      expect(movie.year, 2024);
      expect(movie.posterUrl, 'https://example.com/poster.jpg');
      expect(movie.genres, ['Action', 'Drama']);
      expect(movie.popularity, 8.5);
      expect(movie.runtime, 120);
    });

    test('toJson creates correct map', () {
      final movie = MovieModel(
        id: '123',
        tmdbId: 456,
        title: 'Test Movie',
        year: 2024,
        posterUrl: 'https://example.com/poster.jpg',
        genres: const ['Action'],
        popularity: 7.0,
        runtime: 100,
        cachedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        lastSyncedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = movie.toJson();

      expect(json['id'], '123');
      expect(json['tmdb_id'], 456);
      expect(json['title'], 'Test Movie');
      expect(json['genres'], ['Action']);
    });

    test('fromTmdb creates MovieModel correctly', () {
      final tmdbJson = {
        'id': 456,
        'title': 'TMDB Movie',
        'release_date': '2024-05-15',
        'poster_path': '/poster.jpg',
        'popularity': 9.0,
        'runtime': 130,
      };

      final movie = MovieModel.fromTmdb(tmdbJson);

      expect(movie.tmdbId, 456);
      expect(movie.title, 'TMDB Movie');
      expect(movie.year, 2024);
      expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
      expect(movie.popularity, 9.0);
      expect(movie.runtime, 130);
    });

    test('fromTmdb handles missing optional fields', () {
      final tmdbJson = {
        'id': 789,
        'title': 'Minimal Movie',
      };

      final movie = MovieModel.fromTmdb(tmdbJson);

      expect(movie.tmdbId, 789);
      expect(movie.title, 'Minimal Movie');
      expect(movie.year, null);
      expect(movie.posterUrl, null);
      expect(movie.runtime, null);
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/movies/movies_provider_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/movies/movies_provider_test.dart && git commit -m "test: add MovieModel tests"
```

---

## Self-Review

- [ ] Phase 2 Movie Cache DB: TMDB API client, MovieModel, MoviesRepository, MoviesProvider
- [ ] All files created with actual code, no placeholders
- [ ] No TODOs or TBDs remaining
- [ ] Tests for MovieModel included
- [ ] Next: Phase 3 Core Swipe UI

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-2-movie-cache-db.md`**

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session, batch execution with checkpoints

Which approach?