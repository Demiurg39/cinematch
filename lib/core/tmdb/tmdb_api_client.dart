import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'tmdb_endpoints.dart';

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
    String? region,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'language': language,
    };
    if (region != null) params['region'] = region;
    final response = await _dio.get(
      TmdbEndpoints.popularMovies,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> searchMovies({
    required String query,
    int page = 1,
    String language = 'en-US',
    String? region,
  }) async {
    final params = <String, dynamic>{
      'query': query,
      'page': page,
      'language': language,
    };
    if (region != null) params['region'] = region;
    final response = await _dio.get(
      TmdbEndpoints.searchMovies,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetails({
    required int tmdbId,
    String language = 'en-US',
    String? region,
  }) async {
    final params = <String, dynamic>{'language': language};
    if (region != null) params['region'] = region;
    final response = await _dio.get(
      TmdbEndpoints.movieDetail(tmdbId),
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWatchProviders({
    required int tmdbId,
    String watchRegion = 'US',
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.movieWatchProviders(tmdbId),
      queryParameters: {'watch_region': watchRegion, 'language': language},
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

  Future<Map<String, dynamic>> getMovieVideos({
    required int tmdbId,
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      TmdbEndpoints.movieVideos(tmdbId),
      queryParameters: {'language': language},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> discoverMovies({
    int page = 1,
    List<int>? withGenres,
    String language = 'en-US',
    String? region,
    String sortBy = 'popularity.desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'language': language,
      'sort_by': sortBy,
    };
    if (region != null) queryParams['region'] = region;
    if (withGenres != null && withGenres.isNotEmpty) {
      queryParams['with_genres'] = withGenres.join(',');
    }
    final response = await _dio.get(
      TmdbEndpoints.discoverMovies,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}