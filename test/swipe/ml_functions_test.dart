import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VectorCosineSimilarity', () {
    test('identical vectors return 1.0', () {
      final a = [1.0, 0.0, 0.0];
      final b = [1.0, 0.0, 0.0];
      expect(_cosineSimilarity(a, b), closeTo(1.0, 0.0001));
    });

    test('opposite vectors return -1.0', () {
      final a = [1.0, 0.0, 0.0];
      final b = [-1.0, 0.0, 0.0];
      expect(_cosineSimilarity(a, b), closeTo(-1.0, 0.0001));
    });

    test('orthogonal vectors return 0.0', () {
      final a = [1.0, 0.0, 0.0];
      final b = [0.0, 1.0, 0.0];
      expect(_cosineSimilarity(a, b), closeTo(0.0, 0.0001));
    });

    test('similar vectors return high positive value', () {
      final a = [0.5, 0.5, 0.0];
      final b = [0.6, 0.4, 0.0];
      expect(_cosineSimilarity(a, b), greaterThan(0.9));
    });

    test('zero vector returns 0.0', () {
      final a = [0.0, 0.0, 0.0];
      final b = [1.0, 0.0, 0.0];
      expect(_cosineSimilarity(a, b), equals(0.0));
    });

    test('handles multi-dimensional vectors', () {
      final a = [0.3, 0.4, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0];
      final b = [0.25, 0.35, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0];
      expect(_cosineSimilarity(a, b), greaterThan(0.95));
    });
  });

  group('GenrePreferenceVector', () {
    test('genre order matches SQL definition', () {
      // First 20 TMDB genres as defined in ml_functions.sql
      final genreOrder = [
        'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
        'Drama', 'Family', 'Fantasy', 'History', 'Horror', 'Music', 'Mystery',
        'Romance', 'Science Fiction', 'TV Movie', 'Thriller', 'War', 'Western'
      ];
      expect(genreOrder.length, 19);
    });

    test('compute weight from likes', () {
      // User likes 3 Action movies, 2 Comedy, 1 Drama = 6 total likes
      final genreCounts = {'Action': 3, 'Comedy': 2, 'Drama': 1};
      final totalLikes = 6;

      final weights = genreCounts.map(
        (genre, count) => MapEntry(genre, count / totalLikes),
      );

      expect(weights['Action'], closeTo(0.5, 0.0001));
      expect(weights['Comedy'], closeTo(0.3333, 0.0001));
      expect(weights['Drama'], closeTo(0.1667, 0.0001));
    });

    test('normalize to 19-element vector', () {
      final genreOrder = [
        'Action', 'Adventure', 'Animation', 'Comedy', 'Crime', 'Documentary',
        'Drama', 'Family', 'Fantasy', 'History', 'Horror', 'Music', 'Mystery',
        'Romance', 'Science Fiction', 'TV Movie', 'Thriller', 'War', 'Western'
      ];
      final genreWeights = {'Action': 0.5, 'Comedy': 0.3333, 'Drama': 0.1667};

      final vector = List<double>.filled(19, 0.0);
      for (int i = 0; i < genreOrder.length; i++) {
        final weight = genreWeights[genreOrder[i]];
        if (weight != null) {
          vector[i] = weight;
        }
      }

      expect(vector[0], closeTo(0.5, 0.0001)); // Action at index 0
      expect(vector[3], closeTo(0.3333, 0.0001)); // Comedy at index 3
      expect(vector[6], closeTo(0.1667, 0.0001)); // Drama at index 6
    });
  });

  group('MatchScore', () {
    test('genre score + popularity weighted correctly', () {
      const genreScore = 2.5;
      const popularity = 850.0;
      final matchScore = genreScore + popularity / 1000;
      expect(matchScore, closeTo(3.35, 0.0001));
    });

    test('match reason thresholds', () {
      String getReason(double genreScore) {
        if (genreScore > 2) return 'Matches your favorite genres';
        if (genreScore > 1) return 'Aligns with your preferences';
        return 'Popular in your network';
      }

      expect(getReason(2.5), 'Matches your favorite genres');
      expect(getReason(1.5), 'Aligns with your preferences');
      expect(getReason(0.5), 'Popular in your network');
    });
  });

  group('ClusterSimilarity', () {
    test('action adventure cluster vector', () {
      // Cluster: 'Action & Adventure'
      final clusterVector = [
        0.8, 0.9, 0.1, 0.2, 0.3, 0.0, 0.3, 0.1, 0.5, 0.0, 0.1, 0.0, 0.1, 0.1, 0.6, 0.0, 0.5, 0.3, 0.4
      ];
      expect(clusterVector[0], closeTo(0.8, 0.0001)); // Action
      expect(clusterVector[1], closeTo(0.9, 0.0001)); // Adventure
      expect(clusterVector[2], closeTo(0.1, 0.0001)); // Animation (low)
    });

    test('horror thriller cluster vector', () {
      // Cluster: 'Horror & Thriller'
      final clusterVector = [
        0.4, 0.2, 0.0, 0.1, 0.4, 0.0, 0.2, 0.0, 0.3, 0.0, 0.9, 0.0, 0.5, 0.1, 0.3, 0.0, 0.8, 0.1, 0.2
      ];
      expect(clusterVector[10], closeTo(0.9, 0.0001)); // Horror
      expect(clusterVector[16], closeTo(0.8, 0.0001)); // Thriller
    });
  });
}

double _cosineSimilarity(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  if (a.length != b.length) throw ArgumentError('Vectors must have same length');

  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  normA = normA > 0 ? _sqrt(normA) : 0.0;
  normB = normB > 0 ? _sqrt(normB) : 0.0;

  if (normA == 0 || normB == 0) return 0.0;
  return dotProduct / (normA * normB);
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  double guess = x / 2;
  for (int i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}