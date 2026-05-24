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

    // Fetch genre list once for mapping
    final genreData = await _tmdbApi.getGenreList();
    final genres = genreData['genres'] as List<dynamic>;
    final genreMap = {for (var g in genres) g['id'] as int: g['name'] as String};

    final movies = <MovieModel>[];
    for (final json in results) {
      movies.add(MovieModel.fromTmdb(json as Map<String, dynamic>, genreMap: genreMap));
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

    // Fetch genre list for mapping
    final genreData = await _tmdbApi.getGenreList();
    final genres = genreData['genres'] as List<dynamic>;
    final genreMap = {for (var g in genres) g['id'] as int: g['name'] as String};

    final movies = <MovieModel>[];
    for (final json in results) {
      movies.add(MovieModel.fromTmdb(json as Map<String, dynamic>, genreMap: genreMap));
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

    // Fetch genre list for mapping
    final genreData = await _tmdbApi.getGenreList();
    final genres = genreData['genres'] as List<dynamic>;
    final genreMap = {for (var g in genres) g['id'] as int: g['name'] as String};

    final movies = <MovieModel>[];
    for (final json in results) {
      final movie = MovieModel.fromTmdb(json as Map<String, dynamic>, genreMap: genreMap);
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

      // Get genre names from TMDB details response directly
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
        'p_user_id': userId,
        'p_exclude_swiped': true,
        'p_limit_count': limit,
      });

      final results = response as List<dynamic>;
      if (results.isEmpty) return [];

      // Convert RPC result to MovieModel
      return results.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['id'] = json['out_movie_id'] ?? '';
        json['tmdb_id'] = json['out_tmdb_id'];
        json['title'] = json['out_title'];
        json['overview'] = json['overview'];
        json['year'] = json['out_year'];
        json['poster_url'] = json['out_poster_url'];
        json['genres'] = json['out_genres'] ?? [];
        json['popularity'] = (json['out_popularity'] as num?)?.toDouble() ?? 0;
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

    // Fetch genres for movies that don't have them
    final moviesNeedingGenres = <MovieModel>[];
    final moviesWithGenres = <MovieModel>[];

    for (final movie in movies) {
      if (movie.genres.isEmpty) {
        moviesNeedingGenres.add(movie);
      } else {
        moviesWithGenres.add(movie);
      }
    }

    // Try to fetch genres for movies missing them
    if (moviesNeedingGenres.isNotEmpty) {
      try {
        final genreData = await _tmdbApi.getGenreList();
        final genres = genreData['genres'] as List<dynamic>;
        final genreMap = {for (var g in genres) g['id'] as int: g['name'] as String};

        for (final movie in moviesNeedingGenres) {
          try {
            final details = await _tmdbApi.getMovieDetails(tmdbId: movie.tmdbId);
            final genreIds = (details['genres'] as List<dynamic>?)
                ?.map((g) => g['id'] as int)
                .toList() ?? [];
            final genreNames = genreIds
                .map((id) => genreMap[id])
                .whereType<String>()
                .toList();

            moviesWithGenres.add(movie.copyWith(genres: genreNames));
          } catch (_) {
            // Fall back to caching without genres
            moviesWithGenres.add(movie);
          }
        }
      } catch (_) {
        // Can't fetch genres - cache movies as-is
        moviesWithGenres.addAll(moviesNeedingGenres);
      }
    }

    final batch = moviesWithGenres.map((movie) => {
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

    // Generate embeddings for newly cached movies in background
    _generateEmbeddings(moviesWithGenres);
  }

  Future<void> _generateEmbeddings(List<MovieModel> movies) async {
    for (final movie in movies) {
      try {
        await _supabase.rpc('generate_movie_embedding', params: {
          'p_movie_id': movie.id,
        });
      } catch (_) {
        // Silently skip - embeddings will be generated on next cache
      }
    }
  }

  Future<String?> getMovieTrailerKey(int tmdbId, {String language = 'en-US'}) async {
    try {
      final data = await _tmdbApi.getMovieVideos(tmdbId: tmdbId, language: language);
      final results = data['results'] as List<dynamic>? ?? [];
      // Prefer official trailer on YouTube
      final trailer = (results.cast<Map<String, dynamic>>()).firstWhere(
        (v) =>
            v['type'] == 'Trailer' &&
            v['site'] == 'YouTube' &&
            v['official'] == true,
        orElse: () => results.firstWhere(
          (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
          orElse: () => results.firstWhere(
            (v) => v['site'] == 'YouTube',
            orElse: () => <String, dynamic>{},
          ),
        ),
      );
      return trailer['key'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<int> refreshMoviesWithoutGenres({int batchSize = 10}) async {
    // Find movies missing genres
    final response = await _supabase
        .from('movies')
        .select('tmdb_id, title')
        .or('genres.is.null,genres.eq.{}')
        .limit(batchSize);

    if ((response as List).isEmpty) return 0;

    final genreData = await _tmdbApi.getGenreList();
    final genres = genreData['genres'] as List<dynamic>;
    final genreMap = {for (var g in genres) g['id'] as int: g['name'] as String};

    int refreshed = 0;
    for (final movieJson in response) {
      final tmdbId = movieJson['tmdb_id'] as int;
      try {
        final details = await _tmdbApi.getMovieDetails(tmdbId: tmdbId);
        final genreIds = (details['genres'] as List<dynamic>?)
            ?.map((g) => g['id'] as int)
            .toList() ?? [];
        final genreNames = genreIds
            .map((id) => genreMap[id])
            .whereType<String>()
            .toList();

        await _supabase.from('movies').update({
          'genres': genreNames,
          'last_synced_at': DateTime.now().toIso8601String(),
        }).eq('tmdb_id', tmdbId);

        refreshed++;
      } catch (_) {
        // Skip this movie
      }
    }

    return refreshed;
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

  Future<List<Map<String, dynamic>>> getUserGenrePreferences(String userId) async {
    try {
      final response = await _supabase.rpc('get_user_genre_preferences', params: {
        'p_user_id': userId,
      });
      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<MovieModel>> getVectorRecommendations({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc('get_vector_recommendations', params: {
        'p_user_id': userId,
        'p_limit_count': limit,
      });

      final results = response as List<dynamic>;
      if (results.isEmpty) return [];

      return results.map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        json['id'] = json['out_movie_id'] ?? '';
        json['tmdb_id'] = json['out_tmdb_id'];
        json['title'] = json['out_title'];
        json['year'] = json['out_year'];
        json['poster_url'] = json['out_poster_url'];
        json['genres'] = json['out_genres'] ?? [];
        json['popularity'] = (json['out_popularity'] as num?)?.toDouble() ?? 0;
        json['cached_at'] = DateTime.now().toIso8601String();
        return MovieModel.fromJson(json);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}