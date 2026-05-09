import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/matches/domain/match_model.dart';

void main() {
  group('MatchModel', () {
    test('fromJson creates MatchModel correctly', () {
      final json = {
        'id': 'match-123',
        'user_id': 'user-456',
        'tmdb_id': 789,
        'movie_title': 'Test Movie',
        'poster_url': 'https://example.com/poster.jpg',
        'created_at': '2024-01-01T00:00:00.000Z',
        'matched_userId': 'user-999',
        'matched_username': 'partner',
      };

      final match = MatchModel.fromJson(json);

      expect(match.id, 'match-123');
      expect(match.oderId, 'user-456');
      expect(match.tmdbId, 789);
      expect(match.movieTitle, 'Test Movie');
      expect(match.posterUrl, 'https://example.com/poster.jpg');
      expect(match.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
      expect(match.matchedUserId, 'user-999');
      expect(match.matchedUsername, 'partner');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'match-123',
        'user_id': 'user-456',
        'tmdb_id': 789,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final match = MatchModel.fromJson(json);

      expect(match.movieTitle, null);
      expect(match.posterUrl, null);
      expect(match.matchedUserId, '');
      expect(match.matchedUsername, 'Unknown');
    });

    test('fromJson handles null matched fields', () {
      final json = {
        'id': 'match-123',
        'user_id': 'user-456',
        'tmdb_id': 789,
        'created_at': '2024-01-01T00:00:00.000Z',
        'matched_userId': null,
        'matched_username': null,
      };

      final match = MatchModel.fromJson(json);

      expect(match.matchedUserId, '');
      expect(match.matchedUsername, 'Unknown');
    });
  });
}
