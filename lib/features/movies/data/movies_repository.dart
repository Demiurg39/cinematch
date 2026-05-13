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
      movies.add(MovieModel.fromTmdb(json as Map<String, dynamic>));
    }

    // Cache movies - wrap in try-catch to handle RLS during heavy swiping
    try {
      await _cacheMovies(movies);
    } catch (_) {
      // Silently ignore caching errors - movies still returned from TMDB
    }

    return movies;
  }

  Future<List<MovieModel>> discoverMoviesByGenre({
    required List<int> genreIds,
    int page = 1,
  }) async {
    final data = await _tmdbApi.discoverMovies(
      page: page,
      withGenres: genreIds,
    );
    final results = data['results'] as List<dynamic>;

    final movies = <MovieModel>[];
    for (final json in results) {
      movies.add(MovieModel.fromTmdb(json as Map<String, dynamic>));
    }

    try {
      await _cacheMovies(movies);
    } catch (_) {}

    return movies;
  }

  Future<List<MovieModel>> getCachedMovies({
    int limit = 50,
    List<int>? excludeTmdbIds,
  }) async {
    final response = await _supabase
        .from('movies')
        .select()
        .order('popularity', ascending: false)
        .limit(limit + 50); // Overfetch to account for filtering

    var movies = (response as List<dynamic>)
        .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Filter out excluded tmdbIds client-side
    if (excludeTmdbIds != null && excludeTmdbIds.isNotEmpty) {
      movies = movies.where((m) => !excludeTmdbIds.contains(m.tmdbId)).toList();
      if (movies.length > limit) {
        movies = movies.sublist(0, limit);
      }
    }

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

  Future<Map<String, dynamic>?> getWatchProviders(int tmdbId, {String watchRegion = 'US'}) async {
    return await _tmdbApi.getWatchProviders(tmdbId: tmdbId, watchRegion: watchRegion);
  }

  Future<MovieModel?> refreshMovieDetails(int tmdbId) async {
    try {
      final data = await _tmdbApi.getMovieDetails(tmdbId: tmdbId);
      final movie = MovieModel.fromTmdb(data);

      // Get genre names from filter if available
      final genreData = await _tmdbApi.getGenreList();
      final genres = genreData['genres'] as List<dynamic>;
      final genreMap = {for (var g in genres) g['id']: g['name']};
      final genreNames = (data['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String?)
          .whereType<String>()
          .toList() ?? [];

      final refreshedMovie = MovieModel(
        id: movie.id,
        tmdbId: movie.tmdbId,
        title: movie.title,
        overview: data['overview'] as String?,
        year: movie.year,
        posterUrl: movie.posterUrl,
        genres: genreNames,
        popularity: movie.popularity,
        runtime: data['runtime'] as int?,
        cachedAt: DateTime.now(),
        lastSyncedAt: DateTime.now(),
      );

      // Update cache
      await _cacheMovies([refreshedMovie]);

      return refreshedMovie;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getGenreList() async {
    final data = await _tmdbApi.getGenreList();
    final genres = data['genres'] as List<dynamic>;
    return genres.map((g) => g as Map<String, dynamic>).toList();
  }

  Future<List<MovieModel>> getRecommendedMovies({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc('get_recommended_movies', params: {
        'user_id_param': userId,
        'exclude_swiped': true,
        'limit_count': limit,
      });

      final results = response as List<dynamic>;
      if (results.isEmpty) return [];

      // Convert RPC result (without id field) to MovieModel using fromJson
      return results.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['id'] = '';
        json['tmdb_id'] = json['tmdb_id'];
        json['title'] = json['title'];
        json['overview'] = json['overview'];
        json['year'] = json['year'];
        json['poster_url'] = json['poster_url'];
        json['genres'] = json['genres'] ?? [];
        json['popularity'] = json['popularity'] ?? 0;
        json['cached_at'] = DateTime.now().toIso8601String();
        return MovieModel.fromJson(json);
      }).toList();
    } catch (e) {
      // Fall back to empty list on error - caller handles fallback to popular
      return [];
    }
  }

  Future<void> _cacheMovies(List<MovieModel> movies) async {
    if (movies.isEmpty) return;
    final batch = movies.map((movie) => {
      'tmdb_id': movie.tmdbId,
      'title': movie.title,
      'overview': movie.overview,
      'year': movie.year,
      'poster_url': movie.posterUrl,
      'genres': movie.genres,
      'popularity': movie.popularity,
      'runtime': movie.runtime,
      'cached_at': DateTime.now().toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    }).toList();
    await _supabase.from('movies').upsert(batch, onConflict: 'tmdb_id');
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