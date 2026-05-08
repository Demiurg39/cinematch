import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import 'tmdb_endpoints.dart';

class TmdbApiClient {
  TmdbApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = 'https://api.themoviedb.org/3';
    _dio.options.queryParameters = {
      'api_key': dotenv.env['TMDB_API_KEY'] ?? AppConstants.tmdbApiKey,
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