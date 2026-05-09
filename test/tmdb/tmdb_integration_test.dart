import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/core/constants/app_constants.dart';

void main() {
  group('TMDB API Integration', () {
    test('getPopularMovies returns valid response structure', () async {
      final data = await _get('/movie/popular', queryParams: {'page': '1', 'language': 'en-US'});

      expect(data.containsKey('page'), true);
      expect(data.containsKey('results'), true);
      expect(data.containsKey('total_pages'), true);
      expect(data.containsKey('total_results'), true);

      expect(data['page'], isA<int>());
      expect(data['results'], isA<List>());
      expect((data['results'] as List).isNotEmpty, true);

      final firstMovie = data['results'][0] as Map<String, dynamic>;
      _validateMovieSummary(firstMovie);
    });

    test('searchMovies returns valid results structure', () async {
      final data = await _get('/search/movie', queryParams: {'query': 'Batman'});

      expect(data['page'], 1);
      expect(data['results'], isA<List>());
      expect((data['results'] as List).isNotEmpty, true);

      final firstResult = data['results'][0] as Map<String, dynamic>;
      _validateMovieSummary(firstResult);
      expect(
        firstResult['title'].toString().toLowerCase(),
        contains('batman'),
      );
    });

    test('getMovieDetails returns full movie data', () async {
      final data = await _get('/movie/157336', queryParams: {'language': 'en-US'});

      expect(data['id'], 157336);
      expect(data['title'], isA<String>());
      expect(data.containsKey('overview'), true);
      expect(data.containsKey('release_date'), true);
      expect(data.containsKey('genres'), true);
      expect(data['genres'], isA<List>());
    });

    test('getGenreList returns movie genres', () async {
      final data = await _get('/genre/movie/list', queryParams: {'language': 'en-US'});

      expect(data.containsKey('genres'), true);
      expect(data['genres'], isA<List>());
      expect((data['genres'] as List).isNotEmpty, true);

      final firstGenre = data['genres'][0] as Map<String, dynamic>;
      expect(firstGenre.containsKey('id'), true);
      expect(firstGenre.containsKey('name'), true);
      expect(firstGenre['id'], isA<int>());
      expect(firstGenre['name'], isA<String>());
    });

    test('getMovieDetails includes runtime and vote_average', () async {
      final data = await _get('/movie/157336', queryParams: {'language': 'en-US'});

      expect(data.containsKey('runtime'), true);
      expect(data['runtime'], isA<int?>() ?? isA<int>());
      expect(data.containsKey('vote_average'), true);
      expect(data['vote_average'], isA<double>());
    });

    test('searchMovies handles empty query gracefully', () async {
      final data = await _get(
        '/search/movie',
        queryParams: {'query': 'ZZZZ_NO_MOVIE_XYZ_12345'},
      );

      expect(data['page'], 1);
      expect(data['results'], isA<List>());
      expect((data['results'] as List).isEmpty, true);
      expect(data['total_results'], 0);
    });
  });
}

Future<Map<String, dynamic>> _get(
  String path, {
  Map<String, String>? queryParams,
}) async {
  final apiKey = AppConstants.tmdbApiKey;
  final uri = Uri.parse('https://api.themoviedb.org/3$path').replace(
    queryParameters: {...?queryParams, 'api_key': apiKey},
  );

  final response = await http.get(uri);
  expect(response.statusCode, 200, reason: 'API call failed: ${response.body}');
  return json.decode(response.body) as Map<String, dynamic>;
}

void _validateMovieSummary(Map<String, dynamic> movie) {
  expect(movie.containsKey('id'), true);
  expect(movie.containsKey('title'), true);
  expect(movie['id'], isA<int>());
  expect(movie['title'], isA<String>());
}