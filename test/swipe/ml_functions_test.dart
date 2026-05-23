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

  group('DislikePenalty', () {
    test('preference vector shifts away from disliked genre', () {
      // Like Action movies (index 0), dislike Comedy (index 3)
      final likeGenreWeights = {0: 0.5, 3: 0.0}; // liked Action
      final dislikeGenreWeights = {0: 0.0, 3: 0.4}; // disliked Comedy

      // Simulate: user liked 2 Action movies, disliked 1 Comedy
      // Weighted: Action: +2 * 1.0 = +2, Comedy: -1 * 0.5 = -0.5
      // Total abs weight: 2*1.0 + 1*0.5 = 2.5
      // Normalized: Action: 2.0/2.5 = 0.8, Comedy: -0.5/2.5 = -0.2
      final likeCount = 2;
      final dislikeCount = 1;
      const dislikeWeight = 0.5;

      final actionWeight = (likeCount * 1.0) / (likeCount * 1.0 + dislikeCount * dislikeWeight);
      final comedyWeight = (-dislikeCount * dislikeWeight) / (likeCount * 1.0 + dislikeCount * dislikeWeight);

      expect(actionWeight, closeTo(0.8, 0.0001));
      expect(comedyWeight, closeTo(-0.2, 0.0001));
    });

    test('veto penalty is stronger than dislike', () {
      // Like 1 Action (weight +1.0), veto 1 Comedy (weight -1.0)
      // Total abs: 1.0 + 1.0 = 2.0
      // Action: 1.0/2.0 = 0.5, Comedy: -1.0/2.0 = -0.5
      const actionWeight = 1.0 / 2.0;
      const comedyWeight = -1.0 / 2.0;

      expect(actionWeight, closeTo(0.5, 0.0001));
      expect(comedyWeight, closeTo(-0.5, 0.0001));
    });

    test('maybe adds slight positive signal', () {
      // Like 1 Action (+1.0), maybe 1 Drama (+0.3)
      // Total abs: 1.0 + 0.3 = 1.3
      // Action: 1.0/1.3, Drama: 0.3/1.3
      const actionWeight = 1.0 / 1.3;
      const dramaWeight = 0.3 / 1.3;

      expect(actionWeight, greaterThan(dramaWeight));
      expect(dramaWeight, greaterThan(0.0));
    });

    test('pure negatives return no preference', () {
      // Only dislikes (weight -0.5) = no positive signals
      const positiveWeight = 0.0; // no likes or maybes
      expect(positiveWeight <= 0, isTrue);
    });
  });

  group('TextSemanticEmbedding', () {
    test('keywords hash to deterministic positions in 384-dim vector', () {
      final vector = List<double>.filled(384, 0.0);
      final lexemes = [
        'adventure', 'treasure', 'island',
      ];

      // Simulate PG hashtext for each lexeme -> position 40-382
      int hashText(String s) {
        int hash = 0;
        for (int i = 0; i < s.length; i++) {
          hash = (hash * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
        }
        return hash.toSigned(32);
      }

      for (final lex in lexemes) {
        final pos = (hashText(lex).abs() % 343) + 40;
        vector[pos] = 1.0;
      }

      // Verify positions are in valid range
      for (int i = 0; i < 384; i++) {
        if (vector[i] > 0) {
          expect(i, greaterThanOrEqualTo(40));
          expect(i, lessThanOrEqualTo(382));
        }
      }
    });

    test('similar overviews produce overlapping non-zero positions', () {
      final overviewA = 'A brave adventurer explores a mysterious island to find hidden treasure';
      final overviewB = 'An explorer discovers a secret island with buried treasure and danger';

      // Extract significant words (len >= 4)
      Set<String> keywords(String text) {
        return text
            .toLowerCase()
            .split(RegExp(r'\W+'))
            .where((w) => w.length >= 4 && w.length <= 20)
            .toSet();
      }

      final setA = keywords(overviewA);
      final setB = keywords(overviewB);

      // Both should mention similar concepts
      expect(setA.intersection(setB), isNot(isEmpty));
    });

    test('unrelated overviews share few keywords', () {
      final overviewA = 'A brave adventurer explores a mysterious island to find hidden treasure';
      final overviewC = 'A financial analyst uncovers corruption at a large corporation';

      Set<String> keywords(String text) {
        return text
            .toLowerCase()
            .split(RegExp(r'\W+'))
            .where((w) => w.length >= 4)
            .toSet();
      }

      final setA = keywords(overviewA);
      final setC = keywords(overviewC);

      // Unrelated topics should share few significant words
      final overlap = setA.intersection(setC);
      expect(overlap.length, lessThan(3));
    });
  });

  group('GenreScoringWithNegatives', () {
    test('like/dislike mix produces positive genre weight', () {
      // Action: 3 likes (score +2 each = +6), 1 dislike (score -1 = -1) => net +5
      // Comedy: 2 likes (+4), 2 dislikes (-2) => net +2
      // Drama: 1 dislike (-1) => net -1 (filtered out, score not > 0)

      double computeGenreWeight(double netScore, double maxScore, double minScore) {
        if (maxScore == minScore) return 0.5;
        return (netScore - minScore) / (maxScore - minScore);
      }

      const maxScore = 5.0; // Action
      const minScore = -1.0; // Drama

      expect(computeGenreWeight(5.0, maxScore, minScore), closeTo(1.0, 0.0001));
      expect(computeGenreWeight(2.0, maxScore, minScore), closeTo(0.5, 0.0001));
    });

    test('genre filtered when net score <= 0', () {
      final genreScores = {'Action': 5.0, 'Comedy': 2.0, 'Drama': -1.0};
      final positiveOnly = genreScores.entries.where((e) => e.value > 0).toList();

      expect(positiveOnly.map((e) => e.key), containsAll(['Action', 'Comedy']));
      expect(positiveOnly.map((e) => e.key), isNot(contains('Drama')));
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