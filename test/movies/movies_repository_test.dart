import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';

void main() {
  group('MoviesRepository helpers', () {
    test('MovieModel fromJson with all fields', () {
      final json = {
        'id': 'cached-123',
        'tmdb_id': 456,
        'title': 'Cached Movie',
        'year': 2023,
        'poster_url': 'https://example.com/cached.jpg',
        'genres': ['Drama', 'Comedy'],
        'popularity': 7.5,
        'runtime': 115,
        'cached_at': '2024-01-01T00:00:00.000Z',
        'last_synced_at': '2024-01-02T00:00:00.000Z',
      };

      final movie = MovieModel.fromJson(json);

      expect(movie.id, 'cached-123');
      expect(movie.tmdbId, 456);
      expect(movie.title, 'Cached Movie');
      expect(movie.year, 2023);
      expect(movie.posterUrl, 'https://example.com/cached.jpg');
      expect(movie.genres, ['Drama', 'Comedy']);
      expect(movie.popularity, 7.5);
      expect(movie.runtime, 115);
      expect(movie.cachedAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(movie.lastSyncedAt, DateTime.parse('2024-01-02T00:00:00.000Z'));
    });

    test('MovieModel fromJson empty genres list', () {
      final json = {
        'id': '123',
        'tmdb_id': 456,
        'title': 'Movie',
        'cached_at': '2024-01-01T00:00:00.000Z',
        'genres': null,
      };

      final movie = MovieModel.fromJson(json);

      expect(movie.genres, isEmpty);
    });

    test('MovieModel roundtrip via fromJson and toJson', () {
      final original = MovieModel(
        id: 'roundtrip-123',
        tmdbId: 789,
        title: 'Roundtrip Movie',
        year: 2022,
        posterUrl: 'https://example.com/rt.jpg',
        genres: const ['Action', 'Thriller'],
        popularity: 8.0,
        runtime: 140,
        cachedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        lastSyncedAt: DateTime.parse('2024-01-01T12:00:00.000Z'),
      );

      final json = original.toJson();
      final restored = MovieModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.tmdbId, original.tmdbId);
      expect(restored.title, original.title);
      expect(restored.year, original.year);
      expect(restored.posterUrl, original.posterUrl);
      expect(restored.genres, original.genres);
      expect(restored.popularity, original.popularity);
      expect(restored.runtime, original.runtime);
    });
  });
}
