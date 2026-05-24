enum MatchType { unanimous, shared }

class RoomMatch {
  final String movieId;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final MatchType type;

  const RoomMatch({
    required this.movieId,
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    required this.type,
  });
}
