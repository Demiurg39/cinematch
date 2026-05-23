import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/movies/domain/movie_model.dart';

void main() {
  group('MovieModel vector-related', () {
    test('fromTmdb creates correct genre list via genreMap', () {
      final tmdbJson = {
        'id': 123,
        'title': 'Vector Movie',
        'genre_ids': [28, 12, 878],
        'release_date': '2025-06-15',
        'poster_path': '/test.jpg',
        'popularity': 100.0,
      };

      final genreMap = {
        28: 'Action',
        12: 'Adventure',
        878: 'Science Fiction',
        35: 'Comedy',
      };

      final movie = MovieModel.fromTmdb(tmdbJson, genreMap: genreMap);

      expect(movie.tmdbId, 123);
      expect(movie.title, 'Vector Movie');
      expect(movie.year, 2025);
      expect(movie.genres, containsAll(['Action', 'Adventure', 'Science Fiction']));
      expect(movie.genres, isNot(contains('Comedy')));
      expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/test.jpg');
      expect(movie.popularity, 100.0);
    });

    test('fromTmdb handles missing genre ids', () {
      final tmdbJson = {
        'id': 456,
        'title': 'No Genre Movie',
        'release_date': '2024-01-01',
      };

      final movie = MovieModel.fromTmdb(tmdbJson, genreMap: {});

      expect(movie.genres, isEmpty);
    });

    test('fromTmdb handles unknown genre ids as empty', () {
      final tmdbJson = {
        'id': 789,
        'title': 'Unknown Genre Movie',
        'genre_ids': [9999, 8888],
        'release_date': '2023-05-10',
      };

      final movie = MovieModel.fromTmdb(tmdbJson, genreMap: {28: 'Action'});

      expect(movie.genres, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      final original = MovieModel(
        id: 'orig-1',
        tmdbId: 100,
        title: 'Original',
        year: 2020,
        posterUrl: '/original.jpg',
        genres: const ['Drama'],
        popularity: 50.0,
        runtime: 120,
        cachedAt: DateTime(2024, 1, 1),
        lastSyncedAt: DateTime(2024, 1, 2),
      );

      final copied = original.copyWith(title: 'Updated');

      expect(copied.title, 'Updated');
      expect(copied.tmdbId, 100);
      expect(copied.year, 2020);
      expect(copied.genres, ['Drama']);
      expect(copied.popularity, 50.0);
      expect(copied.runtime, 120);
    });

    test('copyWith updates genres list', () {
      final original = MovieModel(
        id: 'gen-1',
        tmdbId: 200,
        title: 'Genre Test',
        genres: const ['Action'],
        cachedAt: DateTime.now(),
      );

      final updated = original.copyWith(genres: ['Action', 'Comedy']);

      expect(updated.genres, ['Action', 'Comedy']);
      expect(original.genres, ['Action']);
    });
  });
}