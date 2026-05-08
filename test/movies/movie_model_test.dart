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